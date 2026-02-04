// Meal Suggestion Service
// AI-powered meal suggestions based on user's remaining calories and macro balance
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/meal.dart';
import 'database_service.dart';
import 'storage_service.dart';

class MealSuggestionService {
  // API Configuration (same as FoodRecognitionService)
  static const String _apiBaseUrl =
      'https://api.orbit-provider.com/cliproxy-api/api/provider/agy';
  static const String _apiKey = 'sk-orbit-0846cfa453c75d71f36966e14c314e24';
  static const String _model = 'gemini-2.5-flash';

  /// Get meal suggestions based on remaining calories and macro balance
  static Future<MealSuggestionResult> getSuggestions() async {
    try {
      // Get user profile and today's data
      final profile = StorageService.getUserProfile();
      if (profile == null) {
        return MealSuggestionResult.error('Chưa có thông tin người dùng');
      }

      final todayRecord = await DatabaseService.getTodayRecord();
      final todayMeals = await DatabaseService.getTodayMeals();

      // Calculate remaining calories
      final dailyTarget = profile.dailyTarget;
      final consumed = todayRecord.caloIntake;
      final remaining = dailyTarget - consumed;

      // Calculate macro balance
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final meal in todayMeals) {
        totalProtein += meal.protein ?? 0;
        totalCarbs += meal.carbs ?? 0;
        totalFat += meal.fat ?? 0;
      }

      // Determine meal time
      final hour = DateTime.now().hour;
      String mealTime;
      if (hour < 10) {
        mealTime = 'breakfast';
      } else if (hour < 14) {
        mealTime = 'lunch';
      } else if (hour < 17) {
        mealTime = 'snack';
      } else {
        mealTime = 'dinner';
      }

      // Generate suggestions
      final suggestions = await _generateAISuggestions(
        profile: profile,
        remainingCalories: remaining,
        totalProtein: totalProtein,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
        mealTime: mealTime,
      );

      if (suggestions.isEmpty) {
        // Fallback to local suggestions
        return MealSuggestionResult.success(
          _getLocalSuggestions(remaining, mealTime, profile.goal),
          remainingCalories: remaining.toInt(),
          mealTime: mealTime,
        );
      }

      return MealSuggestionResult.success(
        suggestions,
        remainingCalories: remaining.toInt(),
        mealTime: mealTime,
      );
    } catch (e) {
      return MealSuggestionResult.error('Lỗi: $e');
    }
  }

  /// Generate AI-powered suggestions
  static Future<List<MealSuggestion>> _generateAISuggestions({
    required UserProfile profile,
    required double remainingCalories,
    required double totalProtein,
    required double totalCarbs,
    required double totalFat,
    required String mealTime,
  }) async {
    try {
      final prompt =
          '''Bạn là chuyên gia dinh dưỡng Việt Nam. Gợi ý 3-5 món ăn phù hợp cho người dùng.

Thông tin người dùng:
- Mục tiêu: ${_getGoalText(profile.goal)}
- Calories còn lại hôm nay: ${remainingCalories.toInt()} kcal
- Đã nạp: Protein ${totalProtein.toInt()}g, Carbs ${totalCarbs.toInt()}g, Fat ${totalFat.toInt()}g
- Bữa ăn: ${_getMealTimeText(mealTime)}

Yêu cầu:
1. Gợi ý món ăn Việt Nam phổ biến, dễ tìm
2. Phù hợp với lượng calories còn lại
3. Cân bằng dinh dưỡng (nếu thiếu protein thì gợi ý món nhiều protein, v.v.)
4. Phù hợp với bữa ăn hiện tại

Trả về JSON duy nhất, không giải thích:
{
  "suggestions": [
    {
      "name": "Tên món ăn",
      "name_en": "English name",
      "description": "Mô tả ngắn",
      "calories": 300,
      "protein": 20,
      "carbs": 30,
      "fat": 10,
      "reason": "Lý do phù hợp"
    }
  ]
}''';

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
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = '';

        if (data['content'] != null && data['content'] is List) {
          for (var block in data['content']) {
            if (block['type'] == 'text') {
              content = block['text'] ?? '';
              break;
            }
          }
        }

        // Parse JSON from response
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;

        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonStr = content.substring(jsonStart, jsonEnd);
          final suggestionData = jsonDecode(jsonStr);

          if (suggestionData['suggestions'] != null) {
            return (suggestionData['suggestions'] as List)
                .map(
                  (s) => MealSuggestion(
                    name: s['name'] ?? '',
                    nameEn: s['name_en'] ?? s['name'] ?? '',
                    description: s['description'] ?? '',
                    calories: (s['calories'] ?? 0).toDouble(),
                    protein: (s['protein'] ?? 0).toDouble(),
                    carbs: (s['carbs'] ?? 0).toDouble(),
                    fat: (s['fat'] ?? 0).toDouble(),
                    reason: s['reason'] ?? '',
                  ),
                )
                .toList();
          }
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get local fallback suggestions
  static List<MealSuggestion> _getLocalSuggestions(
    double remainingCalories,
    String mealTime,
    String goal,
  ) {
    final suggestions = <MealSuggestion>[];

    // Vietnamese food suggestions based on meal time and goal
    if (mealTime == 'breakfast') {
      if (goal == 'lose') {
        suggestions.addAll([
          MealSuggestion(
            name: 'Cháo yến mạch với trái cây',
            nameEn: 'Oatmeal with fruits',
            description: 'Giàu chất xơ, no lâu',
            calories: 250,
            protein: 8,
            carbs: 45,
            fat: 5,
            reason: 'Ít calories, nhiều chất xơ giúp no lâu',
          ),
          MealSuggestion(
            name: 'Bánh mì trứng ốp la',
            nameEn: 'Bread with fried egg',
            description: 'Protein từ trứng',
            calories: 300,
            protein: 15,
            carbs: 35,
            fat: 12,
            reason: 'Cung cấp protein buổi sáng',
          ),
        ]);
      } else {
        suggestions.addAll([
          MealSuggestion(
            name: 'Phở bò',
            nameEn: 'Beef pho',
            description: 'Món ăn sáng truyền thống',
            calories: 450,
            protein: 25,
            carbs: 55,
            fat: 15,
            reason: 'Đầy đủ dinh dưỡng, protein từ thịt bò',
          ),
          MealSuggestion(
            name: 'Xôi gà',
            nameEn: 'Sticky rice with chicken',
            description: 'Năng lượng cao',
            calories: 500,
            protein: 22,
            carbs: 60,
            fat: 18,
            reason: 'Nhiều năng lượng cho ngày mới',
          ),
        ]);
      }
    } else if (mealTime == 'lunch' || mealTime == 'dinner') {
      if (goal == 'lose') {
        suggestions.addAll([
          MealSuggestion(
            name: 'Cơm gạo lứt với cá hấp',
            nameEn: 'Brown rice with steamed fish',
            description: 'Ít calories, nhiều protein',
            calories: 400,
            protein: 30,
            carbs: 45,
            fat: 10,
            reason: 'Protein cao từ cá, ít chất béo',
          ),
          MealSuggestion(
            name: 'Bún chả cá',
            nameEn: 'Fish cake noodle soup',
            description: 'Nhẹ nhàng, dễ tiêu',
            calories: 350,
            protein: 22,
            carbs: 40,
            fat: 8,
            reason: 'Ít calories nhưng no bụng',
          ),
          MealSuggestion(
            name: 'Salad gà',
            nameEn: 'Chicken salad',
            description: 'Nhiều rau xanh',
            calories: 280,
            protein: 25,
            carbs: 15,
            fat: 12,
            reason: 'Rất ít calories, nhiều vitamin',
          ),
        ]);
      } else {
        suggestions.addAll([
          MealSuggestion(
            name: 'Cơm sườn nướng',
            nameEn: 'Grilled pork chop rice',
            description: 'Thơm ngon, đủ chất',
            calories: 650,
            protein: 35,
            carbs: 65,
            fat: 25,
            reason: 'Cung cấp đủ năng lượng và protein',
          ),
          MealSuggestion(
            name: 'Bún bò Huế',
            nameEn: 'Hue beef noodle soup',
            description: 'Đặc sản miền Trung',
            calories: 550,
            protein: 30,
            carbs: 50,
            fat: 22,
            reason: 'Nhiều protein từ thịt bò',
          ),
        ]);
      }
    } else {
      // Snack
      suggestions.addAll([
        MealSuggestion(
          name: 'Sữa chua Hy Lạp',
          nameEn: 'Greek yogurt',
          description: 'Giàu protein',
          calories: 120,
          protein: 15,
          carbs: 8,
          fat: 3,
          reason: 'Snack giàu protein, ít calories',
        ),
        MealSuggestion(
          name: 'Chuối',
          nameEn: 'Banana',
          description: 'Năng lượng nhanh',
          calories: 100,
          protein: 1,
          carbs: 25,
          fat: 0,
          reason: 'Bổ sung năng lượng nhanh chóng',
        ),
        MealSuggestion(
          name: 'Hạt điều (30g)',
          nameEn: 'Cashew nuts',
          description: 'Chất béo tốt',
          calories: 160,
          protein: 5,
          carbs: 9,
          fat: 13,
          reason: 'Chất béo lành mạnh, no lâu',
        ),
      ]);
    }

    // Filter by remaining calories
    return suggestions
        .where((s) => s.calories <= remainingCalories + 100)
        .toList();
  }

  static String _getGoalText(String goal) {
    switch (goal) {
      case 'lose':
        return 'Giảm cân';
      case 'gain':
        return 'Tăng cân';
      default:
        return 'Duy trì cân nặng';
    }
  }

  static String _getMealTimeText(String mealTime) {
    switch (mealTime) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
      case 'dinner':
        return 'Bữa tối';
      case 'snack':
        return 'Bữa phụ';
      default:
        return mealTime;
    }
  }

  /// Convert suggestion to meal for logging
  static Meal suggestionToMeal(MealSuggestion suggestion) {
    return Meal(
      dateTime: DateTime.now(),
      foodName: suggestion.name,
      calories: suggestion.calories,
      protein: suggestion.protein,
      carbs: suggestion.carbs,
      fat: suggestion.fat,
      source: 'suggestion',
    );
  }
}

/// Result of meal suggestion request
class MealSuggestionResult {
  final bool isSuccess;
  final List<MealSuggestion>? suggestions;
  final int? remainingCalories;
  final String? mealTime;
  final String? error;

  MealSuggestionResult._({
    required this.isSuccess,
    this.suggestions,
    this.remainingCalories,
    this.mealTime,
    this.error,
  });

  factory MealSuggestionResult.success(
    List<MealSuggestion> suggestions, {
    int? remainingCalories,
    String? mealTime,
  }) {
    return MealSuggestionResult._(
      isSuccess: true,
      suggestions: suggestions,
      remainingCalories: remainingCalories,
      mealTime: mealTime,
    );
  }

  factory MealSuggestionResult.error(String message) {
    return MealSuggestionResult._(isSuccess: false, error: message);
  }
}

/// Meal suggestion data
class MealSuggestion {
  final String name;
  final String nameEn;
  final String description;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String reason;

  MealSuggestion({
    required this.name,
    required this.nameEn,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.reason,
  });
}
