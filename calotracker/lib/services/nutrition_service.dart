// Nutrition API Service
// Integration with USDA FoodData Central API for food nutrition data
// Ưu tiên offline FoodDatabase trước khi gọi API bên ngoài
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/meal.dart';
import '../data/food_database.dart';

class NutritionService {
  // USDA FoodData Central API Configuration
  // API Documentation: https://fdc.nal.usda.gov/api-guide.html
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static const String _apiKey = 'M33dVzXOX3T1v1m62O7dbr2nJnsifAnWrZRqFqiD';

  /// Check if API is configured
  static bool get isConfigured =>
      _apiKey.isNotEmpty && _apiKey != 'YOUR_API_KEY';

  /// Query nutrition data from food search
  ///
  /// Ưu tiên: 1) Offline FoodDatabase → 2) USDA API → 3) Demo data
  static Future<NutritionResult> queryNutrition(
    String query, {
    String locale = 'vi_VN',
  }) async {
    // ── Bước 1: Tìm trong offline FoodDatabase trước ──────────────────────
    final offlineResult = _getOfflineData(query);
    if (offlineResult != null) {
      return offlineResult;
    }

    // ── Bước 2: Gọi USDA API nếu có kết nối ──────────────────────────────
    try {
      if (!isConfigured) {
        return _getDemoData(query);
      }

      // Use USDA Food Search API
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/foods/search?query=${Uri.encodeComponent(query)}&api_key=$_apiKey&pageSize=5',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final foods = data['foods'] as List<dynamic>? ?? [];

        if (foods.isEmpty) {
          return _getDemoData(query);
        }

        return NutritionResult.success(NutritionData.fromUSDA(data), data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return NutritionResult.error('API key không hợp lệ');
      } else if (response.statusCode == 404) {
        return _getDemoData(query);
      } else {
        return NutritionResult.error('Lỗi server: ${response.statusCode}');
      }
    } on SocketException {
      // Không có mạng — fallback về demo data
      return _getDemoData(query);
    } on HttpException {
      return _getDemoData(query);
    } catch (e) {
      return NutritionResult.error('Lỗi: $e');
    }
  }

  /// Tìm kiếm trong offline FoodDatabase
  ///
  /// Trả về null nếu không tìm thấy (để fallback sang API)
  static NutritionResult? _getOfflineData(String query) {
    final analysis = FoodDatabaseService.analyze(query);
    if (analysis == null) return null;

    final food = analysis.food;

    // Tạo rawData theo format USDA để tương thích với toMeals()
    final rawData = {
      'source': 'offline_database',
      'foods': [
        {
          'description': food.name,
          'servingSize': analysis.weightGrams,
          'calories': analysis.calories,
          'protein': analysis.protein,
          'carbs': analysis.carbs,
          'fat': analysis.fat,
          'fiber': analysis.fiber,
          'health_score': food.healthScore,
          'alternatives': food.healthierAlternatives,
        }
      ],
    };

    final nutritionData = NutritionData.fromUSDA(rawData);
    return NutritionResult.success(nutritionData, rawData);
  }

  /// Get detailed nutrition for a specific food by FDC ID
  static Future<NutritionResult> getFoodDetails(int fdcId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/food/$fdcId?api_key=$_apiKey'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return NutritionResult.success(NutritionData.fromUSDADetail(data), {
          'foods': [data],
        });
      } else {
        return NutritionResult.error('Không tìm thấy thông tin chi tiết');
      }
    } catch (e) {
      return NutritionResult.error('Lỗi: $e');
    }
  }

  /// Scan food from image - uses demo data since USDA doesn't support image
  static Future<NutritionResult> scanImage(File imageFile) async {
    // USDA API doesn't support image recognition
    // Return demo data
    return _getDemoData('scanned food');
  }

  /// Demo data for testing - Extended Vietnamese food database
  static NutritionResult _getDemoData(String query) {
    final lowerQuery = query.toLowerCase();

    // Extended Vietnamese food database for demo
    final Map<String, Map<String, dynamic>> foodDb = {
      // Món phở
      'phở': {
        'description': 'Phở bò',
        'servingSize': 500,
        'calories': 380,
        'protein': 22,
        'carbs': 55,
        'fat': 8,
      },
      'phở bò': {
        'description': 'Phở bò',
        'servingSize': 500,
        'calories': 380,
        'protein': 22,
        'carbs': 55,
        'fat': 8,
      },
      'phở gà': {
        'description': 'Phở gà',
        'servingSize': 500,
        'calories': 350,
        'protein': 25,
        'carbs': 50,
        'fat': 6,
      },

      // Món cơm
      'cơm': {
        'description': 'Cơm trắng',
        'servingSize': 200,
        'calories': 260,
        'protein': 5,
        'carbs': 56,
        'fat': 0.5,
      },
      'cơm trắng': {
        'description': 'Cơm trắng',
        'servingSize': 200,
        'calories': 260,
        'protein': 5,
        'carbs': 56,
        'fat': 0.5,
      },
      'cơm rang': {
        'description': 'Cơm rang',
        'servingSize': 250,
        'calories': 380,
        'protein': 10,
        'carbs': 52,
        'fat': 14,
      },
      'cơm tấm': {
        'description': 'Cơm tấm sườn',
        'servingSize': 400,
        'calories': 650,
        'protein': 35,
        'carbs': 70,
        'fat': 25,
      },
      'cơm gà': {
        'description': 'Cơm gà',
        'servingSize': 350,
        'calories': 520,
        'protein': 30,
        'carbs': 60,
        'fat': 15,
      },
      'rice': {
        'description': 'White Rice',
        'servingSize': 200,
        'calories': 260,
        'protein': 5,
        'carbs': 56,
        'fat': 0.5,
      },

      // Món gà
      'gà': {
        'description': 'Gà nướng',
        'servingSize': 100,
        'calories': 165,
        'protein': 31,
        'carbs': 0,
        'fat': 3.6,
      },
      'gà nướng': {
        'description': 'Gà nướng',
        'servingSize': 100,
        'calories': 165,
        'protein': 31,
        'carbs': 0,
        'fat': 3.6,
      },
      'gà rán': {
        'description': 'Gà rán',
        'servingSize': 150,
        'calories': 320,
        'protein': 25,
        'carbs': 12,
        'fat': 20,
      },
      'gà luộc': {
        'description': 'Gà luộc',
        'servingSize': 100,
        'calories': 140,
        'protein': 28,
        'carbs': 0,
        'fat': 3,
      },
      'chicken': {
        'description': 'Grilled Chicken',
        'servingSize': 100,
        'calories': 165,
        'protein': 31,
        'carbs': 0,
        'fat': 3.6,
      },

      // Món bún
      'bún': {
        'description': 'Bún bò Huế',
        'servingSize': 450,
        'calories': 420,
        'protein': 25,
        'carbs': 48,
        'fat': 15,
      },
      'bún bò': {
        'description': 'Bún bò Huế',
        'servingSize': 450,
        'calories': 420,
        'protein': 25,
        'carbs': 48,
        'fat': 15,
      },
      'bún chả': {
        'description': 'Bún chả',
        'servingSize': 400,
        'calories': 480,
        'protein': 28,
        'carbs': 45,
        'fat': 20,
      },
      'bún riêu': {
        'description': 'Bún riêu cua',
        'servingSize': 450,
        'calories': 380,
        'protein': 22,
        'carbs': 50,
        'fat': 10,
      },
      'bún thịt nướng': {
        'description': 'Bún thịt nướng',
        'servingSize': 400,
        'calories': 450,
        'protein': 26,
        'carbs': 48,
        'fat': 18,
      },

      // Món bánh mì
      'bánh mì': {
        'description': 'Bánh mì thịt',
        'servingSize': 200,
        'calories': 350,
        'protein': 18,
        'carbs': 45,
        'fat': 12,
      },
      'bánh mì thịt': {
        'description': 'Bánh mì thịt',
        'servingSize': 200,
        'calories': 350,
        'protein': 18,
        'carbs': 45,
        'fat': 12,
      },
      'bánh mì trứng': {
        'description': 'Bánh mì trứng',
        'servingSize': 180,
        'calories': 280,
        'protein': 12,
        'carbs': 40,
        'fat': 8,
      },
      'bread': {
        'description': 'Bread',
        'servingSize': 100,
        'calories': 265,
        'protein': 9,
        'carbs': 49,
        'fat': 3.2,
      },

      // Món trứng
      'trứng': {
        'description': 'Trứng chiên',
        'servingSize': 60,
        'calories': 90,
        'protein': 6,
        'carbs': 0.5,
        'fat': 7,
      },
      'trứng chiên': {
        'description': 'Trứng chiên',
        'servingSize': 60,
        'calories': 90,
        'protein': 6,
        'carbs': 0.5,
        'fat': 7,
      },
      'trứng luộc': {
        'description': 'Trứng luộc',
        'servingSize': 50,
        'calories': 78,
        'protein': 6,
        'carbs': 0.5,
        'fat': 5,
      },
      'trứng ốp la': {
        'description': 'Trứng ốp la',
        'servingSize': 60,
        'calories': 95,
        'protein': 6,
        'carbs': 0.5,
        'fat': 7.5,
      },
      'egg': {
        'description': 'Egg',
        'servingSize': 50,
        'calories': 78,
        'protein': 6,
        'carbs': 0.5,
        'fat': 5,
      },

      // Đồ uống
      'sữa': {
        'description': 'Sữa tươi',
        'servingSize': 240,
        'calories': 120,
        'protein': 8,
        'carbs': 12,
        'fat': 5,
      },
      'cà phê': {
        'description': 'Cà phê sữa đá',
        'servingSize': 250,
        'calories': 150,
        'protein': 2,
        'carbs': 28,
        'fat': 4,
      },
      'cà phê đen': {
        'description': 'Cà phê đen',
        'servingSize': 200,
        'calories': 10,
        'protein': 0.5,
        'carbs': 2,
        'fat': 0,
      },
      'trà sữa': {
        'description': 'Trà sữa trân châu',
        'servingSize': 500,
        'calories': 350,
        'protein': 3,
        'carbs': 65,
        'fat': 8,
      },
      'nước cam': {
        'description': 'Nước cam',
        'servingSize': 250,
        'calories': 110,
        'protein': 2,
        'carbs': 26,
        'fat': 0.5,
      },
      'milk': {
        'description': 'Milk',
        'servingSize': 240,
        'calories': 120,
        'protein': 8,
        'carbs': 12,
        'fat': 5,
      },
      'coffee': {
        'description': 'Coffee with milk',
        'servingSize': 250,
        'calories': 150,
        'protein': 2,
        'carbs': 28,
        'fat': 4,
      },

      // Món khác
      'chả': {
        'description': 'Chả giò',
        'servingSize': 100,
        'calories': 280,
        'protein': 8,
        'carbs': 20,
        'fat': 18,
      },
      'chả giò': {
        'description': 'Chả giò',
        'servingSize': 100,
        'calories': 280,
        'protein': 8,
        'carbs': 20,
        'fat': 18,
      },
      'xôi': {
        'description': 'Xôi gà',
        'servingSize': 300,
        'calories': 450,
        'protein': 15,
        'carbs': 65,
        'fat': 14,
      },
      'xôi gà': {
        'description': 'Xôi gà',
        'servingSize': 300,
        'calories': 450,
        'protein': 15,
        'carbs': 65,
        'fat': 14,
      },
      'xôi xéo': {
        'description': 'Xôi xéo',
        'servingSize': 250,
        'calories': 380,
        'protein': 10,
        'carbs': 60,
        'fat': 12,
      },
      'mì': {
        'description': 'Mì xào',
        'servingSize': 300,
        'calories': 420,
        'protein': 18,
        'carbs': 55,
        'fat': 15,
      },
      'mì xào': {
        'description': 'Mì xào',
        'servingSize': 300,
        'calories': 420,
        'protein': 18,
        'carbs': 55,
        'fat': 15,
      },
      'hủ tiếu': {
        'description': 'Hủ tiếu Nam Vang',
        'servingSize': 450,
        'calories': 400,
        'protein': 24,
        'carbs': 50,
        'fat': 12,
      },

      // Thịt
      'thịt bò': {
        'description': 'Thịt bò',
        'servingSize': 100,
        'calories': 250,
        'protein': 26,
        'carbs': 0,
        'fat': 15,
      },
      'thịt heo': {
        'description': 'Thịt heo',
        'servingSize': 100,
        'calories': 240,
        'protein': 22,
        'carbs': 0,
        'fat': 16,
      },
      'thịt nướng': {
        'description': 'Thịt nướng',
        'servingSize': 100,
        'calories': 220,
        'protein': 25,
        'carbs': 2,
        'fat': 12,
      },
      'sườn': {
        'description': 'Sườn nướng',
        'servingSize': 150,
        'calories': 380,
        'protein': 28,
        'carbs': 5,
        'fat': 28,
      },
      'beef': {
        'description': 'Beef',
        'servingSize': 100,
        'calories': 250,
        'protein': 26,
        'carbs': 0,
        'fat': 15,
      },
      'pork': {
        'description': 'Pork',
        'servingSize': 100,
        'calories': 240,
        'protein': 22,
        'carbs': 0,
        'fat': 16,
      },

      // Hải sản
      'cá': {
        'description': 'Cá chiên',
        'servingSize': 150,
        'calories': 200,
        'protein': 25,
        'carbs': 5,
        'fat': 10,
      },
      'tôm': {
        'description': 'Tôm rang',
        'servingSize': 100,
        'calories': 120,
        'protein': 24,
        'carbs': 1,
        'fat': 2,
      },
      'mực': {
        'description': 'Mực xào',
        'servingSize': 100,
        'calories': 130,
        'protein': 18,
        'carbs': 4,
        'fat': 5,
      },
      'fish': {
        'description': 'Fish',
        'servingSize': 150,
        'calories': 200,
        'protein': 25,
        'carbs': 5,
        'fat': 10,
      },
      'shrimp': {
        'description': 'Shrimp',
        'servingSize': 100,
        'calories': 120,
        'protein': 24,
        'carbs': 1,
        'fat': 2,
      },

      // Rau củ
      'salad': {
        'description': 'Salad rau',
        'servingSize': 150,
        'calories': 50,
        'protein': 2,
        'carbs': 8,
        'fat': 1,
      },
      'rau': {
        'description': 'Rau xào',
        'servingSize': 150,
        'calories': 80,
        'protein': 3,
        'carbs': 8,
        'fat': 4,
      },
      'canh': {
        'description': 'Canh rau',
        'servingSize': 250,
        'calories': 45,
        'protein': 2,
        'carbs': 6,
        'fat': 1.5,
      },
      'vegetable': {
        'description': 'Vegetables',
        'servingSize': 150,
        'calories': 50,
        'protein': 2,
        'carbs': 8,
        'fat': 1,
      },

      // Món tráng miệng
      'chè': {
        'description': 'Chè đậu',
        'servingSize': 200,
        'calories': 180,
        'protein': 4,
        'carbs': 38,
        'fat': 2,
      },
      'bánh': {
        'description': 'Bánh ngọt',
        'servingSize': 100,
        'calories': 350,
        'protein': 5,
        'carbs': 45,
        'fat': 16,
      },
      'kem': {
        'description': 'Kem',
        'servingSize': 100,
        'calories': 200,
        'protein': 3,
        'carbs': 24,
        'fat': 10,
      },
      'cake': {
        'description': 'Cake',
        'servingSize': 100,
        'calories': 350,
        'protein': 5,
        'carbs': 45,
        'fat': 16,
      },

      // Trái cây
      'chuối': {
        'description': 'Chuối',
        'servingSize': 120,
        'calories': 105,
        'protein': 1.3,
        'carbs': 27,
        'fat': 0.4,
      },
      'táo': {
        'description': 'Táo',
        'servingSize': 180,
        'calories': 95,
        'protein': 0.5,
        'carbs': 25,
        'fat': 0.3,
      },
      'cam': {
        'description': 'Cam',
        'servingSize': 150,
        'calories': 70,
        'protein': 1.3,
        'carbs': 18,
        'fat': 0.2,
      },
      'xoài': {
        'description': 'Xoài',
        'servingSize': 165,
        'calories': 100,
        'protein': 1.4,
        'carbs': 25,
        'fat': 0.6,
      },
      'banana': {
        'description': 'Banana',
        'servingSize': 120,
        'calories': 105,
        'protein': 1.3,
        'carbs': 27,
        'fat': 0.4,
      },
      'apple': {
        'description': 'Apple',
        'servingSize': 180,
        'calories': 95,
        'protein': 0.5,
        'carbs': 25,
        'fat': 0.3,
      },
      'orange': {
        'description': 'Orange',
        'servingSize': 150,
        'calories': 70,
        'protein': 1.3,
        'carbs': 18,
        'fat': 0.2,
      },
    };

    // Find matching foods
    List<Map<String, dynamic>> matchedFoods = [];

    // First try exact match
    if (foodDb.containsKey(lowerQuery)) {
      matchedFoods.add(foodDb[lowerQuery]!);
    } else {
      // Try partial match
      for (final entry in foodDb.entries) {
        if (lowerQuery.contains(entry.key) || entry.key.contains(lowerQuery)) {
          matchedFoods.add(entry.value);
          break; // Take first match
        }
      }
    }

    // If no match, return generic food with message
    if (matchedFoods.isEmpty) {
      matchedFoods.add({
        'description': query,
        'servingSize': 100,
        'calories': 150,
        'protein': 8,
        'carbs': 18,
        'fat': 5,
      });
    }

    final responseData = {'foods': matchedFoods};
    return NutritionResult.success(
      NutritionData.fromUSDA(responseData),
      responseData,
    );
  }

  /// Convert nutrition result to meals
  static List<Meal> toMeals(NutritionResult result, String source) {
    if (!result.isSuccess || result.rawData == null) return [];

    final foods = result.rawData!['foods'] as List<dynamic>? ?? [];
    return foods
        .map((food) => Meal.fromUSDA(food as Map<String, dynamic>, source))
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
