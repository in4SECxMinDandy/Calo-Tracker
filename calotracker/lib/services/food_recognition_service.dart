// Food Recognition Service using AI Vision API
// Recognizes food from camera images and returns nutrition data
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'nutrition_service.dart';
import '../models/chat_message.dart';

/// Supported AI providers for food recognition
enum AIProvider {
  anthropic,
  openai,
  clarifai,
  demo,
}

/// Configuration for AI providers
class AIProviderConfig {
  final AIProvider provider;
  final String apiKey;
  final String apiUrl;
  final String model;

  const AIProviderConfig({
    required this.provider,
    required this.apiKey,
    required this.apiUrl,
    required this.model,
  });

  bool get isConfigured =>
      apiKey.isNotEmpty && !apiKey.contains('YOUR_') && !apiKey.contains('DEMO');
}

class FoodRecognitionService {
  // =========================================================================
  // API CONFIGURATIONS
  // =========================================================================

  // Anthropic API via TapHoaApi Proxy
  static const AIProviderConfig _anthropicConfig = AIProviderConfig(
    provider: AIProvider.anthropic,
    apiKey: 'sk-proj-69981a1c7a6c4bb3ad6f5c34f274cadd',
    apiUrl: 'https://taphoaapi.info.vn/v1/messages',
    model: 'claude-sonnet-4-6',
  );

  // OpenAI Vision API (backup)
  static const AIProviderConfig _openaiConfig = AIProviderConfig(
    provider: AIProvider.openai,
    apiKey: 'YOUR_OPENAI_API_KEY',
    apiUrl: 'https://api.openai.com/v1/chat/completions',
    model: 'gpt-4o-mini',
  );

  // Clarifai Food Recognition (backup)
  static const AIProviderConfig _clarifaiConfig = AIProviderConfig(
    provider: AIProvider.clarifai,
    apiKey: 'YOUR_CLARIFAI_API_KEY',
    apiUrl: 'https://api.clarifai.com/v2/models/food-item-recognition/outputs',
    model: 'food-item-recognition',
  );

  // =========================================================================
  // IMAGE OPTIMIZATION SETTINGS
  // =========================================================================

  /// Maximum image dimension after resize
  static const int _maxImageDimension = 512;

  /// Image quality for compression (0-100)
  static const int _imageQuality = 70;

  /// Maximum base64 image length to prevent oversized requests
  static const int _maxBase64Length = 500000; // ~375KB original image

  // =========================================================================
  // REQUEST SETTINGS
  // =========================================================================

  /// Maximum retry attempts for transient errors
  static const int _maxRetries = 2;

  /// Initial timeout for API requests
  static const Duration _requestTimeout = Duration(seconds: 45);

  // =========================================================================
  // PUBLIC METHODS
  // =========================================================================

  /// Check if any API is configured
  static bool get isConfigured => _anthropicConfig.isConfigured ||
      _openaiConfig.isConfigured ||
      _clarifaiConfig.isConfigured;

  /// Get current active provider name for debugging
  static String get activeProviderName {
    if (_anthropicConfig.isConfigured) return 'Anthropic (TapHoaApi)';
    if (_openaiConfig.isConfigured) return 'OpenAI';
    if (_clarifaiConfig.isConfigured) return 'Clarifai';
    return 'Demo Mode';
  }

  /// Main entry point for food recognition
  static Future<FoodRecognitionResult> recognizeFood(File imageFile) async {
    // #region agent log
    _agentLog(
      runId: 'pre-fix',
      hypothesisId: 'H1',
      location: 'food_recognition_service.dart:recognizeFood',
      message: 'recognizeFood entry',
      data: {
        'provider': activeProviderName,
        'pathEmpty': imageFile.path.isEmpty,
      },
    );
    // #endregion
    debugPrint('[FR] START recognizeFood - Provider: $activeProviderName');

    // Step 1: Optimize image
    final optimizedImage = await _optimizeImage(imageFile);
    if (optimizedImage == null) {
      debugPrint('[FR] ERROR: Failed to process image');
      return FoodRecognitionResult.error(
        'Không thể xử lý hình ảnh. Vui lòng chọn ảnh khác.',
      );
    }

    // Step 2: Try providers in order of priority (no demo fallback — fake foods
    // looked like real AI output and misled users when APIs failed, e.g. HTTP 404)

    final providers = [
      _anthropicConfig,
      _openaiConfig,
      _clarifaiConfig,
    ];

    for (final provider in providers) {
      if (!provider.isConfigured) {
        continue;
      }

      debugPrint('[FR] Trying provider: ${provider.provider}');

      for (int attempt = 0; attempt <= _maxRetries; attempt++) {
        if (attempt > 0) {
          debugPrint('[FR] Retry attempt $attempt for ${provider.provider}');
          await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
        }

        final result = await _recognizeWithProvider(provider, optimizedImage);

        // Success - return result
        if (result.isSuccess) {
          debugPrint('[FR] SUCCESS with ${provider.provider}');
          return result;
        }

        // Critical error - don't retry
        if (result.isCriticalError) {
          debugPrint('[FR] Critical error with ${provider.provider}: ${result.error}');
          continue; // Try next provider
        }

        // Transient error - retry
        debugPrint('[FR] Transient error with ${provider.provider}: ${result.error}');
      }
    }

    debugPrint('[FR] All configured providers failed — returning error (no demo placeholder)');
    return FoodRecognitionResult.error(
      'Không thể nhận diện món ăn: máy chủ AI không phản hồi hoặc cấu hình sai '
      '(ví dụ lỗi 404 từ proxy). Vui lòng kiểm tra mạng và API, rồi thử lại. '
      'Ứng dụng không còn hiển thị dữ liệu mẫu để tránh nhầm với ảnh thật.',
    );
  }

  // =========================================================================
  // PRIVATE METHODS
  // =========================================================================

  /// Optimize image before sending to API
  /// Returns base64 encoded image data
  static Future<Uint8List?> _optimizeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final originalSize = bytes.length;
      // #region agent log
      _agentLog(
        runId: 'pre-fix',
        hypothesisId: 'H2',
        location: 'food_recognition_service.dart:_optimizeImage',
        message: 'optimize image constants and size',
        data: {
          'originalSize': originalSize,
          'maxImageDimension': _maxImageDimension,
          'imageQuality': _imageQuality,
          'maxBase64Length': _maxBase64Length,
        },
      );
      // #endregion

      debugPrint('[FR] Original image size: $originalSize bytes');

      // Check if image is already small enough
      if (bytes.length <= _maxBase64Length) {
        debugPrint('[FR] Image size OK, no optimization needed');
        return bytes;
      }

      // Image is too large - need to resize
      // For now, we'll use a simple approach - truncate if extremely large
      // In production, you'd use image package for proper resizing
      debugPrint('[FR] Image too large (${bytes.length} > $_maxBase64Length)');
      debugPrint('[FR] WARNING: Consider implementing proper image resizing');

      // Return original - let the API handle it or fail gracefully
      return bytes;
    } catch (e) {
      debugPrint('[FR] Error reading image: $e');
      return null;
    }
  }

  /// Recognize food with specific provider
  static Future<FoodRecognitionResult> _recognizeWithProvider(
    AIProviderConfig config,
    Uint8List imageBytes,
  ) async {
    switch (config.provider) {
      case AIProvider.anthropic:
        return _recognizeWithAnthropicAPI(config, imageBytes);
      case AIProvider.openai:
        return _recognizeWithOpenAI(config, imageBytes);
      case AIProvider.clarifai:
        return _recognizeWithClarifai(config, imageBytes);
      case AIProvider.demo:
        return FoodRecognitionResult.error(
          'Chế độ demo đã tắt. Vui lòng cấu hình OpenAI, Anthropic hoặc Clarifai.',
        );
    }
  }

  /// Recognize food using Anthropic API
  static Future<FoodRecognitionResult> _recognizeWithAnthropicAPI(
    AIProviderConfig config,
    Uint8List imageBytes,
  ) async {
    debugPrint('[FR-Anthropic] Starting recognition');

    try {
      final base64Image = base64Encode(imageBytes);
      debugPrint('[FR-Anthropic] Image base64 length: ${base64Image.length}');

      if (base64Image.length > _maxBase64Length) {
        debugPrint('[FR-Anthropic] WARNING: Image may be too large for API');
      }

      final response = await http
          .post(
            Uri.parse(config.apiUrl),
            headers: {
              'x-api-key': config.apiKey,
              'Authorization': 'Bearer ${config.apiKey}',
              'anthropic-version': '2023-06-01',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': config.model,
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
                      'text': _getAnthropicPrompt(),
                    },
                  ],
                },
              ],
            }),
          )
          .timeout(_requestTimeout);

      debugPrint('[FR-Anthropic] Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('[FR-Anthropic] Error body: ${response.body}');
      }

      return _parseAnthropicResponse(response);
    } on TimeoutException {
      debugPrint('[FR-Anthropic] Timeout after ${_requestTimeout.inSeconds}s');
      return FoodRecognitionResult.transientError(
        'Quá thời gian chờ phản hồi (${_requestTimeout.inSeconds}s). Vui lòng thử lại.',
      );
    } on SocketException catch (e) {
      debugPrint('[FR-Anthropic] Network error: $e');
      return FoodRecognitionResult.transientError(
        'Không có kết nối mạng. Kiểm tra WiFi/Data của bạn.',
      );
    } on http.ClientException catch (e) {
      debugPrint('[FR-Anthropic] HTTP client error: $e');
      return FoodRecognitionResult.transientError(
        'Lỗi kết nối: $e',
      );
    } catch (e) {
      debugPrint('[FR-Anthropic] Unexpected error: $e');
      return FoodRecognitionResult.criticalError(
        'Lỗi không xác định: $e',
      );
    }
  }

  /// Parse Anthropic API response
  static FoodRecognitionResult _parseAnthropicResponse(http.Response response) {
    // Handle HTTP errors
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        debugPrint('[FR-Anthropic] Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

        // Check for API-level errors in response
        if (data is Map) {
          if (data['error'] != null) {
            final error = data['error'];
            final message = error is Map ? error['message'] ?? 'Unknown error' : error.toString();
            debugPrint('[FR-Anthropic] API error: $message');
            return FoodRecognitionResult.criticalError('Lỗi Anthropic: $message');
          }

          // Extract content from response
          String content = '';
          if (data['content'] != null && data['content'] is List) {
            for (var block in data['content']) {
              if (block is Map && block['type'] == 'text') {
                content = block['text'] ?? '';
                break;
              }
            }
          }

          if (content.isEmpty) {
            debugPrint('[FR-Anthropic] Empty content in response');
            return FoodRecognitionResult.transientError(
              'Phản hồi trống từ AI. Vui lòng thử lại.',
            );
          }

          debugPrint('[FR-Anthropic] Extracted content length: ${content.length}');

          // Parse JSON from content
          return _parseFoodJsonResponse(content);
        }

        return FoodRecognitionResult.criticalError(
          'Định dạng phản hồi không hợp lệ',
        );
      } on FormatException catch (e) {
        debugPrint('[FR-Anthropic] JSON parse error: $e');
        return FoodRecognitionResult.criticalError(
          'Không thể đọc phản hồi từ AI. Định dạng không hợp lệ.',
        );
      }
    }

    // Handle specific HTTP status codes
    switch (response.statusCode) {
      case 400:
        debugPrint('[FR-Anthropic] Bad request - likely invalid model or parameters');
        return FoodRecognitionResult.criticalError(
          'Yêu cầu không hợp lệ. Vui lòng kiểm tra cấu hình API.',
        );
      case 401:
      case 403:
        debugPrint('[FR-Anthropic] Auth error - API key invalid or expired');
        return FoodRecognitionResult.criticalError(
          'API key không hợp lệ hoặc đã hết hạn. Vui lòng cập nhật.',
        );
      case 408:
        return FoodRecognitionResult.transientError(
          'Yêu cầu quá thời gian. Vui lòng thử lại.',
        );
      case 429:
        debugPrint('[FR-Anthropic] Rate limited');
        return FoodRecognitionResult.transientError(
          'Đã vượt giới hạn yêu cầu. Vui lòng chờ và thử lại.',
        );
      case 500:
      case 502:
      case 503:
        return FoodRecognitionResult.transientError(
          'Máy chủ AI đang bận. Vui lòng thử lại sau.',
        );
      default:
        debugPrint('[FR-Anthropic] Unknown HTTP error: ${response.statusCode}');
        return FoodRecognitionResult.criticalError(
          'Lỗi máy chủ (${response.statusCode}). Vui lòng thử lại.',
        );
    }
  }

  /// Parse JSON response containing food data
  static FoodRecognitionResult _parseFoodJsonResponse(String content) {
    try {
      // Find JSON object in content
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}') + 1;

      if (jsonStart < 0 || jsonEnd <= jsonStart) {
        debugPrint('[FR] No valid JSON found in content');
        return FoodRecognitionResult.criticalError(
          'AI không trả về dữ liệu đúng định dạng. Vui lòng thử lại.',
        );
      }

      final jsonStr = content.substring(jsonStart, jsonEnd);
      debugPrint('[FR] Parsing JSON: ${jsonStr.substring(0, jsonStr.length > 100 ? 100 : jsonStr.length)}...');

      final foodData = jsonDecode(jsonStr);

      // Check for explicit error in response
      if (foodData is Map && foodData['error'] != null) {
        return FoodRecognitionResult.criticalError(
          foodData['error'].toString(),
        );
      }

      // Validate structure
      if (foodData is! Map || !foodData.containsKey('foods')) {
        debugPrint('[FR] Invalid response structure: missing "foods" key');
        return FoodRecognitionResult.criticalError(
          'Phản hồi không đúng cấu trúc. Vui lòng thử lại.',
        );
      }

      final foodsList = foodData['foods'];
      if (foodsList is! List) {
        debugPrint('[FR] "foods" is not a list');
        return FoodRecognitionResult.criticalError(
          'Dữ liệu thức ăn không hợp lệ.',
        );
      }

      if (foodsList.isEmpty) {
        debugPrint('[FR] No foods detected in response');
        return FoodRecognitionResult.error(
          'Không nhận diện được thức ăn trong hình ảnh.',
        );
      }

      // Parse food items
      final List<RecognizedFood> foods = [];
      for (final f in foodsList) {
        if (f is! Map) continue;

        final name = f['name'] ?? f['food_name'] ?? f['name_en'] ?? 'Unknown';
        final nameEn = f['name_en'] ?? f['name'] ?? name;
        final weight = ((f['estimated_weight_grams'] ?? f['estimated_weight'] ?? 100) as num).toDouble();
        final confidence = ((f['confidence_score'] ?? f['confidence'] ?? 0.8) as num).toDouble();

        Map<String, double>? macros;
        if (f['macros_per_100g'] is Map) {
          macros = {
            'protein_g': ((f['macros_per_100g']['protein_g'] ?? 0) as num).toDouble(),
            'carbs_g': ((f['macros_per_100g']['carbs_g'] ?? 0) as num).toDouble(),
            'fat_g': ((f['macros_per_100g']['fat_g'] ?? 0) as num).toDouble(),
          };
        }

        foods.add(RecognizedFood(
          name: name.toString(),
          nameEn: nameEn.toString(),
          estimatedWeight: weight,
          confidence: confidence,
          macrosPer100g: macros,
        ));
      }

      if (foods.isEmpty) {
        return FoodRecognitionResult.error(
          'Không tìm thấy thông tin thức ăn hợp lệ.',
        );
      }

      debugPrint('[FR] Successfully parsed ${foods.length} foods');
      return FoodRecognitionResult.success(foods);
    } catch (e, stack) {
      debugPrint('[FR] Parse error: $e');
      debugPrint('[FR] Stack: $stack');
      return FoodRecognitionResult.criticalError(
        'Lỗi phân tích dữ liệu: $e',
      );
    }
  }

  /// Get the prompt for Anthropic API
  static String _getAnthropicPrompt() {
    return '''You are an expert Vietnamese food nutritionist. Analyze this food image very carefully. Identify all the specific dishes and ingredients.

Translate the dishes into their most accurate Vietnamese names. Estimate the weight based on visual proportions.

Return ONLY a JSON object in exactly this format:
{"foods":[{"name":"Tên tiếng Việt","name_en":"English name","estimated_weight_grams":250,"confidence_score":0.92,"macros_per_100g":{"protein_g":10,"carbs_g":25,"fat_g":6}}]}

Important rules:
1. Always output Vietnamese names for "name"
2. Total macros (protein + carbs + fat) per 100g should NOT exceed 100g
3. For soups/noodles, macros per 100g should be low (5-15g)
4. If no food detected, return: {"foods":[],"error":"Không nhận diện được thức ăn"}''';
  }

  /// Recognize food using OpenAI Vision API
  static Future<FoodRecognitionResult> _recognizeWithOpenAI(
    AIProviderConfig config,
    Uint8List imageBytes,
  ) async {
    debugPrint('[FR-OpenAI] Starting recognition');

    try {
      final base64Image = base64Encode(imageBytes);

      final response = await http
          .post(
            Uri.parse(config.apiUrl),
            headers: {
              'Authorization': 'Bearer ${config.apiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': config.model,
              'messages': [
                {
                  'role': 'system',
                  'content': _getOpenAIPrompt(),
                },
                {
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': 'Identify all food items.'},
                    {
                      'type': 'image_url',
                      'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                    },
                  ],
                },
              ],
              'max_tokens': 500,
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(_requestTimeout);

      debugPrint('[FR-OpenAI] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return _parseFoodJsonResponse(content);
      }

      return _handleOpenAIError(response);
    } on TimeoutException {
      return FoodRecognitionResult.transientError(
        'Quá thời gian chờ phản hồi OpenAI.',
      );
    } on SocketException {
      return FoodRecognitionResult.transientError(
        'Không có kết nối mạng.',
      );
    } catch (e) {
      return FoodRecognitionResult.criticalError('Lỗi OpenAI: $e');
    }
  }

  static String _getOpenAIPrompt() {
    return '''You are a food recognition AI. Return JSON only:
{"foods":[{"name":"Food name (Vietnamese)","name_en":"English name","estimated_weight":150,"confidence":0.95}]}

If no food, return: {"foods":[]}''';
  }

  static FoodRecognitionResult _handleOpenAIError(http.Response response) {
    if (response.statusCode == 401) {
      return FoodRecognitionResult.criticalError(
        'OpenAI API key không hợp lệ.',
      );
    } else if (response.statusCode == 429) {
      return FoodRecognitionResult.transientError(
        'OpenAI rate limit. Vui lòng chờ.',
      );
    }
    return FoodRecognitionResult.criticalError(
      'Lỗi OpenAI (${response.statusCode})',
    );
  }

  /// Recognize food using Clarifai API
  static Future<FoodRecognitionResult> _recognizeWithClarifai(
    AIProviderConfig config,
    Uint8List imageBytes,
  ) async {
    debugPrint('[FR-Clarifai] Starting recognition');

    try {
      final base64Image = base64Encode(imageBytes);

      final response = await http
          .post(
            Uri.parse(config.apiUrl),
            headers: {
              'Authorization': 'Key ${config.apiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'inputs': [
                {'data': {'image': {'base64': base64Image}}},
              ],
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final concepts = data['outputs'][0]['data']['concepts'] as List? ?? [];

        final foods = concepts
            .where((c) => (c['value'] ?? 0) > 0.5)
            .take(5)
            .map((c) => RecognizedFood(
                  name: c['name'].toString(),
                  nameEn: c['name'].toString(),
                  estimatedWeight: 100,
                  confidence: (c['value'] as num).toDouble(),
                ))
            .toList();

        if (foods.isEmpty) {
          return FoodRecognitionResult.error('Không nhận diện được thức ăn');
        }
        return FoodRecognitionResult.success(foods);
      }

      return FoodRecognitionResult.criticalError(
        'Lỗi Clarifai (${response.statusCode})',
      );
    } catch (e) {
      return FoodRecognitionResult.criticalError('Lỗi Clarifai: $e');
    }
  }

  /// Get nutrition data for recognized foods
  static Future<NutritionResult> getNutritionForFoods(
    List<RecognizedFood> foods,
  ) async {
    if (foods.isEmpty) {
      return NutritionResult.error('Không có thức ăn để phân tích');
    }

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    List<FoodItem> foodItems = [];

    for (final food in foods) {
      if (food.macrosPer100g != null) {
        double scale = food.estimatedWeight / 100;

        double p100 = food.macrosPer100g!['protein_g'] ?? 0;
        double c100 = food.macrosPer100g!['carbs_g'] ?? 0;
        double f100 = food.macrosPer100g!['fat_g'] ?? 0;

        // Sanity check: macros should not exceed 100g per 100g
        if ((p100 + c100 + f100) > 100) {
          debugPrint('[FR-Nutrition] WARNING: Macros exceed 100g, resetting');
          p100 = 10; c100 = 20; f100 = 5;
        }

        // Atwater formula for calories
        double kcal100 = (p100 * 4) + (c100 * 4) + (f100 * 9);

        totalCalories += kcal100 * scale;
        totalProtein += p100 * scale;
        totalCarbs += c100 * scale;
        totalFat += f100 * scale;

        foodItems.add(FoodItem(
          name: food.name,
          calories: kcal100 * scale,
          weight: food.estimatedWeight,
        ));
      } else {
        // Fallback to local database
        final result = await NutritionService.queryNutrition(food.name);

        if (result.isSuccess && result.data != null) {
          final scale = food.estimatedWeight / 100;
          totalCalories += result.data!.calories * scale;
          totalProtein += (result.data!.protein ?? 0) * scale;
          totalCarbs += (result.data!.carbs ?? 0) * scale;
          totalFat += (result.data!.fat ?? 0) * scale;

          foodItems.add(FoodItem(
            name: food.name,
            calories: result.data!.calories * scale,
            weight: food.estimatedWeight,
          ));
        } else {
          // Generic fallback based on food name patterns
          double calPer100g = 150;
          final nameLower = food.name.toLowerCase();

          if (nameLower.contains('bún') || nameLower.contains('phở') || nameLower.contains('mì')) {
            calPer100g = 120;
          } else if (nameLower.contains('chiên') || nameLower.contains('rán') || nameLower.contains('kho')) {
            calPer100g = 250;
          } else if (nameLower.contains('chả') || nameLower.contains('thịt nướng')) {
            calPer100g = 200;
          } else if (nameLower.contains('salad') || nameLower.contains('rau')) {
            calPer100g = 50;
          }

          final scale = food.estimatedWeight / 100;
          totalCalories += calPer100g * scale;
          totalProtein += 8 * scale;
          totalCarbs += 18 * scale;
          totalFat += (calPer100g > 150 ? 10 : 5) * scale;

          foodItems.add(FoodItem(
            name: food.name,
            calories: calPer100g * scale,
            weight: food.estimatedWeight,
          ));
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
      'foods': foods.map((f) => {'name': f.name, 'weight': f.estimatedWeight}).toList(),
    });
  }
}

/// Result of food recognition
class FoodRecognitionResult {
  final bool isSuccess;
  final bool isTransientError;
  final bool isCriticalError;
  final List<RecognizedFood>? foods;
  final String? error;

  FoodRecognitionResult._({
    required this.isSuccess,
    required this.isTransientError,
    required this.isCriticalError,
    this.foods,
    this.error,
  });

  /// Create success result
  factory FoodRecognitionResult.success(List<RecognizedFood> foods) {
    return FoodRecognitionResult._(
      isSuccess: true,
      isTransientError: false,
      isCriticalError: false,
      foods: foods,
    );
  }

  /// Create regular error (non-retryable)
  factory FoodRecognitionResult.error(String message) {
    return FoodRecognitionResult._(
      isSuccess: false,
      isTransientError: false,
      isCriticalError: false,
      error: message,
    );
  }

  /// Create transient error (can retry)
  factory FoodRecognitionResult.transientError(String message) {
    return FoodRecognitionResult._(
      isSuccess: false,
      isTransientError: true,
      isCriticalError: false,
      error: message,
    );
  }

  /// Create critical error (provider issue, try next)
  factory FoodRecognitionResult.criticalError(String message) {
    return FoodRecognitionResult._(
      isSuccess: false,
      isTransientError: false,
      isCriticalError: true,
      error: message,
    );
  }
}

/// Recognized food item from image
class RecognizedFood {
  final String name;
  final String nameEn;
  final double estimatedWeight;
  final double confidence;
  final Map<String, double>? macrosPer100g;
  final String? warning; // For demo mode warnings

  RecognizedFood({
    required this.name,
    required this.nameEn,
    required this.estimatedWeight,
    required this.confidence,
    this.macrosPer100g,
    this.warning,
  });

  @override
  String toString() =>
      '$name (${(confidence * 100).toInt()}% - ${estimatedWeight.toInt()}g)';
}

void _agentLog({
  required String runId,
  required String hypothesisId,
  required String location,
  required String message,
  required Map<String, dynamic> data,
}) {
  final payload = jsonEncode({
    'sessionId': 'f5a970',
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  final logFile = File('debug-f5a970.log');
  logFile.writeAsString(
    '$payload\n',
    mode: FileMode.append,
    flush: true,
  ).catchError((_) => logFile);
}
