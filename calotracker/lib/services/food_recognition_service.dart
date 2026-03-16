// Food Recognition Service using AI Vision API
// Recognizes food from camera images and returns nutrition data
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'nutrition_service.dart';
import '../models/chat_message.dart';

class FoodRecognitionService {
  // Anthropic (TapHoaApi Proxy) API Configuration
  static const String _anthropicApiKey = 'sk-proj-69981a1c7a6c4bb3ad6f5c34f274cadd';
  static const String _anthropicUrl = 'https://taphoaapi.info.vn/v1/messages';
  static const String _anthropicModel = 'claude-haiku-4-5-20251001';

  // Alternative: OpenAI API (backup)
  static const String _openaiApiKey = 'YOUR_OPENAI_API_KEY';
  static const String _openaiUrl = 'https://api.openai.com/v1/chat/completions';

  // Alternative: Clarifai Food Recognition
  static const String _clarifaiApiKey = 'YOUR_CLARIFAI_API_KEY';
  static const String _clarifaiUrl =
      'https://api.clarifai.com/v2/models/food-item-recognition/outputs';

  /// Check if API is configured
  static bool get isConfigured =>
      _anthropicApiKey.isNotEmpty || _openaiApiKey.isNotEmpty;

  /// Recognize food from image using AI Vision API
  static Future<FoodRecognitionResult> recognizeFood(File imageFile) async {
    // Ưu tiên sử dụng Anthropic API qua proxy của taphoaapi
    if (_anthropicApiKey.isNotEmpty && !_anthropicApiKey.contains('YOUR_ANTHROPIC_API_KEY')) {
      return await _recognizeWithAnthropicAPI(imageFile);
    }

    // Dự phòng OpenAI
    if (_openaiApiKey.isNotEmpty && !_openaiApiKey.contains('YOUR_OPENAI_API_KEY')) {
      return await _recognizeWithOpenAI(imageFile);
    }
    if (_clarifaiApiKey.isNotEmpty &&
        _clarifaiApiKey != 'YOUR_CLARIFAI_API_KEY') {
      return _recognizeWithClarifai(imageFile);
    }

    // No API configured - use demo mode
    return _demoRecognition();
  }

  /// Recognize food using Anthropic API
  static Future<FoodRecognitionResult> _recognizeWithAnthropicAPI(
    File imageFile,
  ) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Anthropic API request (via Proxy)
      final response = await http
          .post(
            Uri.parse(_anthropicUrl),
            headers: {
              'x-api-key': _anthropicApiKey,
              'Authorization': 'Bearer $_anthropicApiKey', // Thêm Authorization đề phòng Proxy yêu cầu
              'anthropic-version': '2023-06-01',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _anthropicModel,
              'max_tokens': 1024,
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'image',
                      'source': {
                        'type': 'base64',
                        'media_type': 'image/jpeg',
                        'data': base64Image,
                      },
                    },
                    {
                      'type': 'text',
                      'text':
                          '''You are an expert Vietnamese food nutritionist. Analyze this food image very carefully. Identify all the specific dishes and ingredients. If it's a traditional dish like "Bún Chả", identify the components properly (Grilled pork, Rice noodles, Herbs, Fish sauce).

Translate the dishes into their most accurate Vietnamese names. Estimate the weight based on visual proportions.

Return ONLY a JSON object in exactly this format without any other markdown or text:
{
  "foods": [
    {
      "name": "Bún chả",
      "name_en": "Grilled pork banh mi",
      "estimated_weight_grams": 250,
      "confidence_score": 0.92,
      "macros_per_100g": {
        "protein_g": 10,
        "carbs_g": 25,
        "fat_g": 6
      }
    }
  ]
}

Very crucial rules:
1. Always output Vietnamese names for "name".
2. Estimate the realistic total weight of the dish in grams.
3. Provide realistic macro breakdown per 100g. Ensure Total Macros (Protein + Carbs + Fat) in 100g NEVER exceeds 100g, and realistically should be much lower because of water content (typically 40%-90% water).
4. If it's a dish with high water content (soups, noodle soups), macros_per_100g will be very low (e.g. 5g-15g).

If no food is detected, return: {"foods": [], "error": "Không nhận diện được thức ăn"}''',
                    },
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Parse Anthropic-style response
        String content = '';
        if (data['content'] != null && data['content'] is List) {
          for (var block in data['content']) {
            if (block['type'] == 'text') {
              content = block['text'] ?? '';
              break;
            }
          }
        }

        // Parse the JSON response
        try {
          final jsonStart = content.indexOf('{');
          final jsonEnd = content.lastIndexOf('}') + 1;
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonStr = content.substring(jsonStart, jsonEnd);
            final foodData = jsonDecode(jsonStr);

            if (foodData['error'] != null) {
              return FoodRecognitionResult.error(foodData['error']);
            }

            final foods =
                (foodData['foods'] as List)
                    .map(
                      (f) => RecognizedFood(
                        name: f['food_name'] ?? f['name'] ?? f['name_en'] ?? 'Unknown',
                        nameEn: f['name_en'] ?? f['name'],
                        estimatedWeight: ((f['estimated_weight_grams'] ?? f['estimated_weight']) ?? 100).toDouble(),
                        confidence: (f['confidence_score'] ?? f['confidence'] ?? 0.8).toDouble(),
                        macrosPer100g: f['macros_per_100g'] != null ? {
                          'protein_g': (f['macros_per_100g']['protein_g'] ?? 0).toDouble(),
                          'carbs_g': (f['macros_per_100g']['carbs_g'] ?? 0).toDouble(),
                          'fat_g': (f['macros_per_100g']['fat_g'] ?? 0).toDouble(),
                        } : null,
                      ),
                    )
                    .toList();

            if (foods.isEmpty) {
              return FoodRecognitionResult.error(
                'Không nhận diện được thức ăn',
              );
            }

            return FoodRecognitionResult.success(foods);
          }
        } catch (e) {
          return FoodRecognitionResult.error('Không thể phân tích kết quả: $e\nNội dung từ API: $content');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return FoodRecognitionResult.error('API key không hợp lệ đối với máy chủ Anthropic');
      } else {
        return FoodRecognitionResult.error(
          'Lỗi máy chủ Anthropic (${response.statusCode}): ${response.body}',
        );
      }

      return FoodRecognitionResult.error('Không thể nhận diện');
    } on TimeoutException {
      return FoodRecognitionResult.error(
        'Quá thời gian chờ phản hồi (60s). Vui lòng thử lại.',
      );
    } on SocketException {
      return FoodRecognitionResult.error('Không có kết nối mạng');
    } catch (e) {
      return FoodRecognitionResult.error('Lỗi: $e');
    }
  }

  /// Recognize food using OpenAI Vision API (GPT-4 Vision)
  static Future<FoodRecognitionResult> _recognizeWithOpenAI(
    File imageFile,
  ) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http
          .post(
            Uri.parse(_openaiUrl),
            headers: {
              'Authorization': 'Bearer $_openaiApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'gpt-4o-mini',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      '''You are a food recognition AI. Analyze the image and identify the food items.
              
Return ONLY a JSON object in this exact format (no markdown, no explanation):
{
  "foods": [
    {
      "name": "Food name in Vietnamese",
      "name_en": "Food name in English",
      "estimated_weight": 150,
      "confidence": 0.95
    }
  ]
}

If no food is detected, return: {"foods": [], "error": "No food detected"}''',
                },
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'text',
                      'text':
                          'Identify all food items in this image. Return JSON only.',
                    },
                    {
                      'type': 'image_url',
                      'image_url': {
                        'url': 'data:image/jpeg;base64,$base64Image',
                      },
                    },
                  ],
                },
              ],
              'max_tokens': 500,
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Parse the JSON response
        try {
          final jsonStart = content.indexOf('{');
          final jsonEnd = content.lastIndexOf('}') + 1;
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonStr = content.substring(jsonStart, jsonEnd);
            final foodData = jsonDecode(jsonStr);

            if (foodData['error'] != null) {
              return FoodRecognitionResult.error(foodData['error']);
            }

            final foods =
                (foodData['foods'] as List)
                    .map(
                      (f) => RecognizedFood(
                        name: f['name'] ?? f['name_en'] ?? 'Unknown',
                        nameEn: f['name_en'] ?? f['name'],
                        estimatedWeight:
                            (f['estimated_weight'] ?? 100).toDouble(),
                        confidence: (f['confidence'] ?? 0.8).toDouble(),
                      ),
                    )
                    .toList();

            return FoodRecognitionResult.success(foods);
          }
        } catch (e) {
          // If JSON parsing fails, try to extract food names
          return FoodRecognitionResult.error('Không thể phân tích kết quả: $content');
        }
      } else if (response.statusCode == 401) {
        return FoodRecognitionResult.error('API key không hợp lệ hoặc đã hết hạn');
      } else {
        return FoodRecognitionResult.error(
          'Lỗi API (${response.statusCode}): ${response.body}',
        );
      }

      return FoodRecognitionResult.error('Không thể nhận diện');
    } on TimeoutException {
      return FoodRecognitionResult.error(
        'Quá thời gian chờ phản hồi (60s). Vui lòng thử lại.',
      );
    } on SocketException {
      return FoodRecognitionResult.error('Không có kết nối mạng');
    } catch (e) {
      return FoodRecognitionResult.error('Lỗi: $e');
    }
  }

  /// Recognize food using Clarifai API
  static Future<FoodRecognitionResult> _recognizeWithClarifai(
    File imageFile,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http
          .post(
            Uri.parse(_clarifaiUrl),
            headers: {
              'Authorization': 'Key $_clarifaiApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'inputs': [
                {
                  'data': {
                    'image': {'base64': base64Image},
                  },
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final concepts = data['outputs'][0]['data']['concepts'] as List? ?? [];

        final foods =
            concepts
                .where((c) => (c['value'] ?? 0) > 0.5) // Filter by confidence
                .take(5) // Max 5 items
                .map(
                  (c) => RecognizedFood(
                    name: c['name'],
                    nameEn: c['name'],
                    estimatedWeight: 100,
                    confidence: c['value'].toDouble(),
                  ),
                )
                .toList();

        if (foods.isEmpty) {
          return FoodRecognitionResult.error('Không nhận diện được thức ăn');
        }

        return FoodRecognitionResult.success(foods);
      } else {
        return FoodRecognitionResult.error(
          'Lỗi Clarifai: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      return FoodRecognitionResult.error(
        'Quá thời gian chờ phản hồi (60s). Vui lòng thử lại.',
      );
    } on SocketException {
      return FoodRecognitionResult.error('Không có kết nối mạng');
    } catch (e) {
      return FoodRecognitionResult.error('Lỗi: $e');
    }
  }

  /// Demo recognition when no API is configured
  static FoodRecognitionResult _demoRecognition() {
    // Return common Vietnamese food for demo
    return FoodRecognitionResult.success([
      RecognizedFood(
        name: 'Cơm trắng',
        nameEn: 'White Rice',
        estimatedWeight: 200,
        confidence: 0.85,
      ),
      RecognizedFood(
        name: 'Thịt kho',
        nameEn: 'Braised Pork',
        estimatedWeight: 100,
        confidence: 0.75,
      ),
    ]);
  }

  /// Get nutrition data for recognized foods
  static Future<NutritionResult> getNutritionForFoods(
    List<RecognizedFood> foods,
  ) async {
    if (foods.isEmpty) {
      return NutritionResult.error('Không có thức ăn để phân tích');
    }

    // Query nutrition for each food
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    List<FoodItem> foodItems = [];

    for (final food in foods) {
      if (food.macrosPer100g != null) {
        // Áp dụng thuật toán Sanity Check nội bộ ngay từ đầu vào API
        double scale = food.estimatedWeight / 100;
        
        double p100 = food.macrosPer100g!['protein_g'] ?? 0;
        double c100 = food.macrosPer100g!['carbs_g'] ?? 0;
        double f100 = food.macrosPer100g!['fat_g'] ?? 0;

        // Validation Rule 1: Bảo toàn khối lượng
        if ((p100 + c100 + f100) > 100) {
           p100 = 10; c100 = 20; f100 = 5; // Reset khẩn cấp nếu bị ảo giác vượt 100%
        }

        // Validation Rule 2: Áp dụng cứng công thức Atwater tính Kcal
        double kcal100 = (p100 * 4) + (c100 * 4) + (f100 * 9);
        
        totalCalories += kcal100 * scale;
        totalProtein += p100 * scale;
        totalCarbs += c100 * scale;
        totalFat += f100 * scale;

        foodItems.add(
          FoodItem(
            name: food.name,
            calories: kcal100 * scale,
            weight: food.estimatedWeight,
          ),
        );
      } else {
        // Fallback về database cũ nếu Model cũ không nhả form mới
        final result = await NutritionService.queryNutrition(food.name);

        if (result.isSuccess && result.data != null) {
          final scale = food.estimatedWeight / 100;
          totalCalories += result.data!.calories * scale;
          totalProtein += (result.data!.protein ?? 0) * scale;
          totalCarbs += (result.data!.carbs ?? 0) * scale;
          totalFat += (result.data!.fat ?? 0) * scale;

          foodItems.add(
            FoodItem(
              name: food.name,
              calories: result.data!.calories * scale,
              weight: food.estimatedWeight,
            ),
          );
        } else {
          // If not found, use a dynamic generic value based on food type
          double calPer100g = 150;
          if (food.name.toLowerCase().contains('bún') || food.name.toLowerCase().contains('phở')) {
            calPer100g = 120;
          } else if (food.name.toLowerCase().contains('chiên') || food.name.toLowerCase().contains('rán')) {
            calPer100g = 250;
          } else if (food.name.toLowerCase().contains('chả')) {
            calPer100g = 200;
          }
          
          totalCalories += calPer100g * (food.estimatedWeight / 100);
          totalProtein += 8 * (food.estimatedWeight / 100);
          totalCarbs += 18 * (food.estimatedWeight / 100);
          totalFat += (calPer100g > 150 ? 10 : 5) * (food.estimatedWeight / 100);

          foodItems.add(
            FoodItem(
              name: food.name,
              calories: calPer100g * (food.estimatedWeight / 100),
              weight: food.estimatedWeight,
            ),
          );
        }
      }
    }

    final nutritionData = NutritionData(
      foods: foodItems,
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
    );

    return NutritionResult.success(nutritionData, {
      'foods':
          foods
              .map((f) => {'name': f.name, 'weight': f.estimatedWeight})
              .toList(),
    });
  }
}

/// Result of food recognition
class FoodRecognitionResult {
  final bool isSuccess;
  final List<RecognizedFood>? foods;
  final String? error;

  FoodRecognitionResult._({required this.isSuccess, this.foods, this.error});

  factory FoodRecognitionResult.success(List<RecognizedFood> foods) {
    return FoodRecognitionResult._(isSuccess: true, foods: foods);
  }

  factory FoodRecognitionResult.error(String message) {
    return FoodRecognitionResult._(isSuccess: false, error: message);
  }
}

/// Recognized food item from image
class RecognizedFood {
  final String name;
  final String nameEn;
  final double estimatedWeight;
  final double confidence;
  final Map<String, double>? macrosPer100g;

  RecognizedFood({
    required this.name,
    required this.nameEn,
    required this.estimatedWeight,
    required this.confidence,
    this.macrosPer100g,
  });

  @override
  String toString() =>
      '$name (${(confidence * 100).toInt()}% - ${estimatedWeight.toInt()}g)';
}
