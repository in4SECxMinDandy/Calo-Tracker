// Nutritionix API Service
// Integration with Nutritionix for food nutrition data
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/meal.dart';

class NutritionixService {
  // API Configuration
  // Note: Replace with your actual Nutritionix API credentials
  static const String _baseUrl = 'https://trackapi.nutritionix.com/v2';
  static const String _appId = 'YOUR_APP_ID'; // Replace with actual App ID
  static const String _apiKey = 'YOUR_API_KEY'; // Replace with actual API Key

  /// Headers for API requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-app-id': _appId,
    'x-app-key': _apiKey,
  };

  /// Check if API is configured
  static bool get isConfigured =>
      _appId != 'YOUR_APP_ID' && _apiKey != 'YOUR_API_KEY';

  /// Query nutrition data from natural language text
  /// Example: "200g cơm trắng + 100g gà nướng"
  static Future<NutritionResult> queryNutrition(
    String query, {
    String locale = 'vi_VN',
  }) async {
    try {
      // For demo mode when API is not configured
      if (!isConfigured) {
        return _getDemoData(query);
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/natural/nutrients'),
            headers: _headers,
            body: jsonEncode({'query': query, 'locale': locale}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return NutritionResult.success(
          NutritionData.fromNutritionix(data),
          data,
        );
      } else if (response.statusCode == 401) {
        return NutritionResult.error('API key không hợp lệ');
      } else if (response.statusCode == 404) {
        return NutritionResult.error('Không tìm thấy món ăn');
      } else {
        return NutritionResult.error('Lỗi server: ${response.statusCode}');
      }
    } on SocketException {
      return NutritionResult.error('Không có kết nối mạng');
    } on HttpException {
      return NutritionResult.error('Lỗi HTTP');
    } catch (e) {
      return NutritionResult.error('Lỗi: $e');
    }
  }

  /// Scan food from image
  static Future<NutritionResult> scanImage(File imageFile) async {
    try {
      if (!isConfigured) {
        return _getDemoData('scanned food');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/natural/nutrients'),
      );

      request.headers.addAll(_headers);
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return NutritionResult.success(
          NutritionData.fromNutritionix(data),
          data,
        );
      } else {
        return NutritionResult.error('Không thể nhận diện món ăn');
      }
    } catch (e) {
      return NutritionResult.error('Lỗi scan ảnh: $e');
    }
  }

  /// Demo data for testing without API
  static NutritionResult _getDemoData(String query) {
    // Simulate API delay
    final lowerQuery = query.toLowerCase();

    // Vietnamese food database for demo
    final Map<String, Map<String, dynamic>> foodDb = {
      'phở': {
        'food_name': 'Phở bò',
        'serving_weight_grams': 500,
        'nf_calories': 380,
        'nf_protein': 22,
        'nf_total_carbohydrate': 55,
        'nf_total_fat': 8,
      },
      'cơm': {
        'food_name': 'Cơm trắng',
        'serving_weight_grams': 200,
        'nf_calories': 260,
        'nf_protein': 5,
        'nf_total_carbohydrate': 56,
        'nf_total_fat': 0.5,
      },
      'gà': {
        'food_name': 'Gà nướng',
        'serving_weight_grams': 100,
        'nf_calories': 165,
        'nf_protein': 31,
        'nf_total_carbohydrate': 0,
        'nf_total_fat': 3.6,
      },
      'bún': {
        'food_name': 'Bún bò Huế',
        'serving_weight_grams': 450,
        'nf_calories': 420,
        'nf_protein': 25,
        'nf_total_carbohydrate': 48,
        'nf_total_fat': 15,
      },
      'bánh mì': {
        'food_name': 'Bánh mì thịt',
        'serving_weight_grams': 200,
        'nf_calories': 350,
        'nf_protein': 18,
        'nf_total_carbohydrate': 45,
        'nf_total_fat': 12,
      },
      'trứng': {
        'food_name': 'Trứng chiên',
        'serving_weight_grams': 60,
        'nf_calories': 90,
        'nf_protein': 6,
        'nf_total_carbohydrate': 0.5,
        'nf_total_fat': 7,
      },
      'sữa': {
        'food_name': 'Sữa tươi',
        'serving_weight_grams': 240,
        'nf_calories': 120,
        'nf_protein': 8,
        'nf_total_carbohydrate': 12,
        'nf_total_fat': 5,
      },
      'cà phê': {
        'food_name': 'Cà phê sữa đá',
        'serving_weight_grams': 250,
        'nf_calories': 150,
        'nf_protein': 2,
        'nf_total_carbohydrate': 28,
        'nf_total_fat': 4,
      },
      'chả': {
        'food_name': 'Chả giò',
        'serving_weight_grams': 100,
        'nf_calories': 280,
        'nf_protein': 8,
        'nf_total_carbohydrate': 20,
        'nf_total_fat': 18,
      },
      'xôi': {
        'food_name': 'Xôi gà',
        'serving_weight_grams': 300,
        'nf_calories': 450,
        'nf_protein': 15,
        'nf_total_carbohydrate': 65,
        'nf_total_fat': 14,
      },
    };

    // Find matching foods
    List<Map<String, dynamic>> matchedFoods = [];

    for (final entry in foodDb.entries) {
      if (lowerQuery.contains(entry.key)) {
        matchedFoods.add(entry.value);
      }
    }

    // If no match, return generic food
    if (matchedFoods.isEmpty) {
      matchedFoods.add({
        'food_name': query,
        'serving_weight_grams': 100,
        'nf_calories': 200,
        'nf_protein': 10,
        'nf_total_carbohydrate': 25,
        'nf_total_fat': 8,
      });
    }

    final responseData = {'foods': matchedFoods};
    return NutritionResult.success(
      NutritionData.fromNutritionix(responseData),
      responseData,
    );
  }

  /// Convert nutrition result to meals
  static List<Meal> toMeals(NutritionResult result, String source) {
    if (!result.isSuccess || result.rawData == null) return [];

    final foods = result.rawData!['foods'] as List<dynamic>? ?? [];
    return foods
        .map(
          (food) => Meal.fromNutritionix(food as Map<String, dynamic>, source),
        )
        .toList();
  }
}

/// Result wrapper for nutrition queries
class NutritionResult {
  final bool isSuccess;
  final NutritionData? data;
  final String? error;
  final Map<String, dynamic>? rawData;

  NutritionResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.rawData,
  });

  factory NutritionResult.success(
    NutritionData data,
    Map<String, dynamic> rawData,
  ) {
    return NutritionResult._(isSuccess: true, data: data, rawData: rawData);
  }

  factory NutritionResult.error(String message) {
    return NutritionResult._(isSuccess: false, error: message);
  }
}
