// Food Recognition Service using AI Vision API
// Recognizes food from camera images and returns nutrition data
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'nutrition_service.dart';
import '../models/chat_message.dart';

class FoodRecognitionService {
  // Orbit API Configuration (Anthropic-compatible with Gemini)
  // Using user's custom API endpoint
  static const String _apiBaseUrl =
      'https://api.orbit-provider.com/cliproxy-api/api/provider/agy';
  static const String _apiKey = 'sk-orbit-96d3d67e76dea5043feb3c5fa64be0c8';
  static const String _model = 'gemini-2.5-flash-preview';

  // Alternative: OpenAI API (backup)
  static const String _openaiApiKey = 'YOUR_OPENAI_API_KEY';
  static const String _openaiUrl = 'https://api.openai.com/v1/chat/completions';

  // Alternative: Clarifai Food Recognition
  static const String _clarifaiApiKey = 'YOUR_CLARIFAI_API_KEY';
  static const String _clarifaiUrl =
      'https://api.clarifai.com/v2/models/food-item-recognition/outputs';

  /// Check if API is configured
  static bool get isConfigured =>
      (_apiKey.isNotEmpty && _apiKey != 'YOUR_API_KEY') ||
      (_openaiApiKey.isNotEmpty && _openaiApiKey != 'YOUR_OPENAI_API_KEY');

  /// Recognize food from image using AI Vision API
  static Future<FoodRecognitionResult> recognizeFood(File imageFile) async {
    // First try Orbit API (Gemini Vision)
    if (_apiKey.isNotEmpty && _apiKey != 'YOUR_API_KEY') {
      return _recognizeWithOrbitAPI(imageFile);
    }

    // Fallback to OpenAI Vision
    if (_openaiApiKey.isNotEmpty && _openaiApiKey != 'YOUR_OPENAI_API_KEY') {
      return _recognizeWithOpenAI(imageFile);
    }

    // Fallback to Clarifai
    if (_clarifaiApiKey.isNotEmpty &&
        _clarifaiApiKey != 'YOUR_CLARIFAI_API_KEY') {
      return _recognizeWithClarifai(imageFile);
    }

    // No API configured - use demo mode with basic recognition
    return _demoRecognition();
  }

  /// Recognize food using Orbit API (Anthropic-compatible with Gemini)
  static Future<FoodRecognitionResult> _recognizeWithOrbitAPI(
    File imageFile,
  ) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Anthropic-style API request with Gemini model
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/v1/messages'),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'anthropic-version': '2023-06-01',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
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
                          '''Analyze this food image. Identify all food items.

Return ONLY a JSON object in this exact format (no markdown, no explanation):
{
  "foods": [
    {
      "name": "Tên món ăn tiếng Việt",
      "name_en": "Food name in English",
      "estimated_weight": 150,
      "confidence": 0.95
    }
  ]
}

If no food is detected, return: {"foods": [], "error": "No food detected"}''',
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
                        name: f['name'] ?? f['name_en'] ?? 'Unknown',
                        nameEn: f['name_en'] ?? f['name'],
                        estimatedWeight:
                            (f['estimated_weight'] ?? 100).toDouble(),
                        confidence: (f['confidence'] ?? 0.8).toDouble(),
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
          return FoodRecognitionResult.error('Không thể phân tích kết quả: $e');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return FoodRecognitionResult.error('API key không hợp lệ');
      } else {
        return FoodRecognitionResult.error(
          'Lỗi server: ${response.statusCode}\n${response.body}',
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
          return FoodRecognitionResult.error('Không thể phân tích kết quả');
        }
      } else if (response.statusCode == 401) {
        return FoodRecognitionResult.error('API key không hợp lệ');
      } else {
        return FoodRecognitionResult.error(
          'Lỗi server: ${response.statusCode}',
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
      // Use Vietnamese name for local database, English for API
      final result = await NutritionService.queryNutrition(food.name);

      if (result.isSuccess && result.data != null) {
        // Scale by estimated weight
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
        // If not found, use estimated values
        foodItems.add(
          FoodItem(
            name: food.name,
            calories: 150 * (food.estimatedWeight / 100),
            weight: food.estimatedWeight,
          ),
        );
        totalCalories += 150 * (food.estimatedWeight / 100);
        totalProtein += 8 * (food.estimatedWeight / 100);
        totalCarbs += 18 * (food.estimatedWeight / 100);
        totalFat += 5 * (food.estimatedWeight / 100);
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

  RecognizedFood({
    required this.name,
    required this.nameEn,
    required this.estimatedWeight,
    required this.confidence,
  });

  @override
  String toString() =>
      '$name (${(confidence * 100).toInt()}% - ${estimatedWeight.toInt()}g)';
}
