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
        // Giảm cân - Bữa sáng (5 món)
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
          MealSuggestion(
            name: 'Cháo gà không dầu mỡ',
            nameEn: 'Chicken congee (low fat)',
            description: 'Nhẹ bụng, dễ tiêu',
            calories: 280,
            protein: 18,
            carbs: 40,
            fat: 4,
            reason: 'Protein cao, ít chất béo',
          ),
          MealSuggestion(
            name: 'Trứng luộc + rau củ luộc',
            nameEn: 'Boiled eggs with steamed vegetables',
            description: 'Sạch, ít dầu mỡ',
            calories: 220,
            protein: 14,
            carbs: 20,
            fat: 8,
            reason: 'Rất ít calories, giàu vitamin',
          ),
          MealSuggestion(
            name: 'Sữa chua không đường + granola',
            nameEn: 'Sugar-free yogurt with granola',
            description: 'Probiotic tốt cho tiêu hóa',
            calories: 240,
            protein: 12,
            carbs: 32,
            fat: 6,
            reason: 'Tốt cho đường ruột, ít calories',
          ),
        ]);
      } else if (goal == 'gain') {
        // Tăng cân - Bữa sáng (5 món)
        suggestions.addAll([
          MealSuggestion(
            name: 'Phở bò đặc biệt',
            nameEn: 'Special beef pho',
            description: 'Nhiều thịt bò, đầy đủ dinh dưỡng',
            calories: 550,
            protein: 32,
            carbs: 60,
            fat: 18,
            reason: 'Protein cao từ thịt bò, năng lượng dồi dào',
          ),
          MealSuggestion(
            name: 'Xôi gà + trứng',
            nameEn: 'Sticky rice with chicken and egg',
            description: 'Năng lượng cao',
            calories: 620,
            protein: 28,
            carbs: 75,
            fat: 22,
            reason: 'Nhiều năng lượng và protein cho ngày mới',
          ),
          MealSuggestion(
            name: 'Bánh mì pate thịt nguội',
            nameEn: 'Vietnamese baguette with pate',
            description: 'Đầy đủ chất, thơm ngon',
            calories: 480,
            protein: 20,
            carbs: 55,
            fat: 20,
            reason: 'Cân bằng macro, dễ ăn',
          ),
          MealSuggestion(
            name: 'Bún bò Huế',
            nameEn: 'Hue beef noodle soup',
            description: 'Đặc sản miền Trung',
            calories: 580,
            protein: 30,
            carbs: 62,
            fat: 22,
            reason: 'Giàu protein và năng lượng',
          ),
          MealSuggestion(
            name: 'Cơm tấm sườn bì chả',
            nameEn: 'Broken rice with grilled pork',
            description: 'Món sáng Sài Gòn',
            calories: 650,
            protein: 35,
            carbs: 68,
            fat: 25,
            reason: 'Rất nhiều protein và calories',
          ),
        ]);
      } else {
        // Duy trì - Bữa sáng (5 món)
        suggestions.addAll([
          MealSuggestion(
            name: 'Phở gà',
            nameEn: 'Chicken pho',
            description: 'Nhẹ nhàng, cân bằng',
            calories: 420,
            protein: 24,
            carbs: 52,
            fat: 12,
            reason: 'Cân bằng dinh dưỡng, dễ tiêu',
          ),
          MealSuggestion(
            name: 'Bánh cuốn nhân thịt',
            nameEn: 'Steamed rice rolls with pork',
            description: 'Mềm mại, thơm ngon',
            calories: 380,
            protein: 18,
            carbs: 48,
            fat: 14,
            reason: 'Vừa đủ năng lượng, không quá nặng',
          ),
          MealSuggestion(
            name: 'Hủ tiếu Nam Vang',
            nameEn: 'Phnom Penh noodle soup',
            description: 'Thanh đạm, ngon miệng',
            calories: 400,
            protein: 22,
            carbs: 50,
            fat: 12,
            reason: 'Đủ chất, không gây nặng bụng',
          ),
          MealSuggestion(
            name: 'Xôi xéo',
            nameEn: 'Sticky rice with mung bean',
            description: 'Truyền thống Hà Nội',
            calories: 450,
            protein: 15,
            carbs: 62,
            fat: 16,
            reason: 'Năng lượng ổn định cả buổi sáng',
          ),
          MealSuggestion(
            name: 'Bún riêu cua',
            nameEn: 'Crab noodle soup',
            description: 'Thanh mát, bổ dưỡng',
            calories: 410,
            protein: 20,
            carbs: 54,
            fat: 11,
            reason: 'Protein từ cua, cân bằng dinh dưỡng',
          ),
        ]);
      }
    } else if (mealTime == 'lunch') {
      if (goal == 'lose') {
        // Giảm cân - Bữa trưa (5 món)
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
            name: 'Salad gà nướng',
            nameEn: 'Grilled chicken salad',
            description: 'Nhiều rau xanh',
            calories: 320,
            protein: 28,
            carbs: 18,
            fat: 14,
            reason: 'Rất ít calories, nhiều vitamin',
          ),
          MealSuggestion(
            name: 'Canh chua cá + cơm gạo lứt',
            nameEn: 'Sour fish soup with brown rice',
            description: 'Thanh mát, ít dầu',
            calories: 380,
            protein: 26,
            carbs: 42,
            fat: 9,
            reason: 'Ít chất béo, nhiều vitamin C',
          ),
          MealSuggestion(
            name: 'Gỏi cuốn tôm thịt (4 cuốn)',
            nameEn: 'Fresh spring rolls',
            description: 'Tươi mát, không chiên',
            calories: 340,
            protein: 20,
            carbs: 38,
            fat: 10,
            reason: 'Sạch, không dầu mỡ, nhiều rau',
          ),
        ]);
      } else if (goal == 'gain') {
        // Tăng cân - Bữa trưa (5 món)
        suggestions.addAll([
          MealSuggestion(
            name: 'Cơm sườn nướng + trứng',
            nameEn: 'Grilled pork chop rice with egg',
            description: 'Thơm ngon, đủ chất',
            calories: 720,
            protein: 40,
            carbs: 70,
            fat: 28,
            reason: 'Protein và năng lượng cao',
          ),
          MealSuggestion(
            name: 'Bún bò Huế đặc biệt',
            nameEn: 'Special Hue beef noodle',
            description: 'Nhiều thịt, giò heo',
            calories: 680,
            protein: 38,
            carbs: 65,
            fat: 26,
            reason: 'Giàu protein từ thịt bò và giò',
          ),
          MealSuggestion(
            name: 'Cơm gà xối mỡ',
            nameEn: 'Chicken rice with fat',
            description: 'Đặc sản Hội An',
            calories: 650,
            protein: 35,
            carbs: 68,
            fat: 24,
            reason: 'Nhiều calories và protein',
          ),
          MealSuggestion(
            name: 'Mì Quảng thịt',
            nameEn: 'Quang noodles with pork',
            description: 'Đặc sản miền Trung',
            calories: 620,
            protein: 32,
            carbs: 72,
            fat: 22,
            reason: 'Đầy đủ dinh dưỡng, nhiều năng lượng',
          ),
          MealSuggestion(
            name: 'Cơm chiên dương châu',
            nameEn: 'Yangzhou fried rice',
            description: 'Nhiều topping',
            calories: 700,
            protein: 30,
            carbs: 80,
            fat: 28,
            reason: 'Calories cao, đa dạng dinh dưỡng',
          ),
        ]);
      } else {
        // Duy trì - Bữa trưa (5 món)
        suggestions.addAll([
          MealSuggestion(
            name: 'Cơm rang thập cẩm',
            nameEn: 'Mixed fried rice',
            description: 'Đa dạng nguyên liệu',
            calories: 520,
            protein: 24,
            carbs: 62,
            fat: 18,
            reason: 'Cân bằng, đủ chất dinh dưỡng',
          ),
          MealSuggestion(
            name: 'Bún chả Hà Nội',
            nameEn: 'Hanoi grilled pork with noodles',
            description: 'Đặc sản Hà thành',
            calories: 480,
            protein: 26,
            carbs: 55,
            fat: 16,
            reason: 'Protein từ thịt nướng, cân bằng',
          ),
          MealSuggestion(
            name: 'Cơm gà Hải Nam',
            nameEn: 'Hainanese chicken rice',
            description: 'Thơm ngon, bổ dưỡng',
            calories: 500,
            protein: 28,
            carbs: 58,
            fat: 16,
            reason: 'Đủ năng lượng, không quá nặng',
          ),
          MealSuggestion(
            name: 'Phở bò tái',
            nameEn: 'Rare beef pho',
            description: 'Món truyền thống',
            calories: 460,
            protein: 26,
            carbs: 56,
            fat: 14,
            reason: 'Cân bằng macro, dễ tiêu hóa',
          ),
          MealSuggestion(
            name: 'Cơm tấm sườn nướng',
            nameEn: 'Broken rice with grilled pork',
            description: 'Món miền Nam',
            calories: 540,
            protein: 30,
            carbs: 60,
            fat: 20,
            reason: 'Đầy đủ dinh dưỡng, ngon miệng',
          ),
        ]);
      }
    } else if (mealTime == 'dinner') {
      if (goal == 'lose') {
        // Giảm cân - Bữa tối (5 món)
        suggestions.addAll([
          MealSuggestion(
            name: 'Canh rau củ + cá hấp',
            nameEn: 'Vegetable soup with steamed fish',
            description: 'Nhẹ bụng, dễ ngủ',
            calories: 320,
            protein: 28,
            carbs: 30,
            fat: 8,
            reason: 'Ít calories, không gây nặng bụng tối',
          ),
          MealSuggestion(
            name: 'Gỏi ngó sen tôm thịt',
            nameEn: 'Lotus root salad with shrimp',
            description: 'Giòn ngon, thanh mát',
            calories: 280,
            protein: 22,
            carbs: 28,
            fat: 9,
            reason: 'Ít calories, nhiều chất xơ',
          ),
          MealSuggestion(
            name: 'Súp gà nấm',
            nameEn: 'Chicken mushroom soup',
            description: 'Ấm bụng, bổ dưỡng',
            calories: 260,
            protein: 24,
            carbs: 20,
            fat: 8,
            reason: 'Protein cao, ít carbs',
          ),
          MealSuggestion(
            name: 'Đậu hũ sốt cà chua',
            nameEn: 'Tofu with tomato sauce',
            description: 'Chay nhẹ, healthy',
            calories: 240,
            protein: 16,
            carbs: 24,
            fat: 10,
            reason: 'Protein thực vật, ít calories',
          ),
          MealSuggestion(
            name: 'Bún rau luộc + tôm',
            nameEn: 'Noodles with boiled vegetables and shrimp',
            description: 'Sạch, ít dầu mỡ',
            calories: 300,
            protein: 20,
            carbs: 36,
            fat: 6,
            reason: 'Rất ít chất béo, nhiều rau',
          ),
        ]);
      } else if (goal == 'gain') {
        // Tăng cân - Bữa tối (5 món)
        suggestions.addAll([
          MealSuggestion(
            name: 'Lẩu thái hải sản',
            nameEn: 'Thai seafood hotpot',
            description: 'Nhiều hải sản, bổ dưỡng',
            calories: 620,
            protein: 42,
            carbs: 50,
            fat: 24,
            reason: 'Protein cao từ hải sản',
          ),
          MealSuggestion(
            name: 'Cơm niêu sườn ram',
            nameEn: 'Clay pot rice with braised pork ribs',
            description: 'Thơm lừng, đậm đà',
            calories: 680,
            protein: 36,
            carbs: 72,
            fat: 26,
            reason: 'Nhiều năng lượng và protein',
          ),
          MealSuggestion(
            name: 'Bún đậu mắm tôm',
            nameEn: 'Noodles with fried tofu and shrimp paste',
            description: 'Đặc sản Hà Nội',
            calories: 650,
            protein: 32,
            carbs: 68,
            fat: 28,
            reason: 'Calories cao, protein từ đậu và thịt',
          ),
          MealSuggestion(
            name: 'Cơm gà rán + khoai tây chiên',
            nameEn: 'Fried chicken rice with fries',
            description: 'Giòn rụm, thơm ngon',
            calories: 720,
            protein: 38,
            carbs: 75,
            fat: 30,
            reason: 'Rất nhiều calories và protein',
          ),
          MealSuggestion(
            name: 'Bánh xèo tôm thịt',
            nameEn: 'Vietnamese savory pancake',
            description: 'Giòn tan, đầy ắp nhân',
            calories: 580,
            protein: 28,
            carbs: 60,
            fat: 26,
            reason: 'Nhiều protein và năng lượng',
          ),
        ]);
      } else {
        // Duy trì - Bữa tối (5 món)
        suggestions.addAll([
          MealSuggestion(
            name: 'Cơm rang dưa bò',
            nameEn: 'Fried rice with pickled vegetables and beef',
            description: 'Đơn giản, ngon miệng',
            calories: 480,
            protein: 26,
            carbs: 56,
            fat: 16,
            reason: 'Cân bằng, dễ tiêu hóa',
          ),
          MealSuggestion(
            name: 'Bún thịt nướng',
            nameEn: 'Grilled pork with vermicelli',
            description: 'Thanh mát, thơm lừng',
            calories: 460,
            protein: 24,
            carbs: 54,
            fat: 16,
            reason: 'Đủ chất, không quá nặng',
          ),
          MealSuggestion(
            name: 'Cá kho tộ + cơm',
            nameEn: 'Braised fish in clay pot with rice',
            description: 'Đậm đà, truyền thống',
            calories: 500,
            protein: 30,
            carbs: 52,
            fat: 18,
            reason: 'Protein từ cá, cân bằng dinh dưỡng',
          ),
          MealSuggestion(
            name: 'Miến gà',
            nameEn: 'Chicken glass noodle soup',
            description: 'Nhẹ nhàng, bổ dưỡng',
            calories: 420,
            protein: 22,
            carbs: 48,
            fat: 14,
            reason: 'Dễ tiêu, không gây nặng bụng',
          ),
          MealSuggestion(
            name: 'Cơm cá thu kho',
            nameEn: 'Braised mackerel with rice',
            description: 'Giàu omega-3',
            calories: 510,
            protein: 28,
            carbs: 54,
            fat: 20,
            reason: 'Chất béo lành mạnh từ cá',
          ),
        ]);
      }
    } else {
      // Snack - Bữa phụ (cho tất cả mục tiêu)
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
        MealSuggestion(
          name: 'Trứng luộc (2 quả)',
          nameEn: 'Boiled eggs',
          description: 'Protein hoàn chỉnh',
          calories: 140,
          protein: 12,
          carbs: 2,
          fat: 10,
          reason: 'Protein chất lượng cao',
        ),
        MealSuggestion(
          name: 'Táo',
          nameEn: 'Apple',
          description: 'Giàu chất xơ',
          calories: 80,
          protein: 0,
          carbs: 21,
          fat: 0,
          reason: 'Ít calories, nhiều vitamin',
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
