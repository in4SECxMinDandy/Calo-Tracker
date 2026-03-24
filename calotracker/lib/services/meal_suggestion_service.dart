// Meal Suggestion Service
// AI-powered meal suggestions based on user's remaining calories and macro balance
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/meal.dart';
import 'database_service.dart';
import 'storage_service.dart';

class MealSuggestionService {
  // API Configuration (TapHoaApi Proxy - Claude Haiku)
  static const String _apiBaseUrl = 'https://taphoaapi.info.vn';
  static const String _apiKey = 'sk-proj-69981a1c7a6c4bb3ad6f5c34f274cadd';
  static const String _model = 'claude-sonnet-4-6';

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
      // Determine remaining meals to help AI calibrate
      int remainingMeals = 1;
      if (mealTime == 'breakfast') {
        remainingMeals = 3;
      } else if (mealTime == 'lunch') {
        remainingMeals = 2;
      } else if (mealTime == 'snack') {
        remainingMeals = 2;
      }

      // Calculate exact calorie target for this meal
      int mealCalTarget = (remainingCalories / remainingMeals).toInt();
      if (mealCalTarget < 150) {
        mealCalTarget = 150; // Tối thiểu 150 kcal (các món siêu nhẹ)
      }
      
      final int mealCalMin = mealCalTarget > 150 ? mealCalTarget - 50 : 50;
      final int mealCalMax = mealCalTarget + 50;

      final prompt =
          '''Bạn là chuyên gia dinh dưỡng Việt Nam. Gợi ý 6-8 món ăn ĐA DẠNG, PHONG PHÚ và PHÙ HỢP NHẤT cho bữa ${_getMealTimeText(mealTime)} này.
Đặc biệt phải bám sát lịch sử nạp calo của người dùng hôm nay!

Thông tin người dùng:
- Mục tiêu sức khỏe: ${_getGoalText(profile.goal)}
- Mục tiêu calo/ngày: ${profile.dailyTarget.toInt()} kcal
- Đã nạp hôm nay: ${(profile.dailyTarget - remainingCalories).toInt()} kcal
- Calo CÒN LẠI hôm nay: ${remainingCalories.toInt()} kcal
- Biến động Macro còn lại (ước tính): Protein ${(profile.dailyTarget * 0.3 / 4 - totalProtein).round()}g, Carbs ${(profile.dailyTarget * 0.4 / 4 - totalCarbs).round()}g, Fat ${(profile.dailyTarget * 0.3 / 9 - totalFat).round()}g
- Số bữa dự kiến còn lại (bao gồm bữa này): $remainingMeals

QUY TẮC BẮT BUỘC - PHÂN CHIA CALO:
1. Mục tiêu calo CHO BỮA NÀY = ${remainingCalories.toInt()} ÷ $remainingMeals = $mealCalTarget kcal.
2. NẾU mục tiêu calo thấp (ví dụ dưới 300kcal) vì họ đã ăn quá nhiều: Bắt buộc gợi ý các món ăn siêu nhẹ, trái cây, salad, hạt, sữa chua...
3. NẾU mục tiêu calo cực cao (ví dụ trên 800kcal): Gợi ý các combo món nhậu, bún/phở size lớn, cơm phần nhiều thịt...
4. Mỗi món gợi ý PHẢI nằm trong dải $mealCalMin – $mealCalMax kcal (sai số ±50 kcal).
5. Chỉ gợi ý MÓN VIỆT NAM phổ biến hoặc dễ mua/làm (cơm, phở, xôi, bún, gỏi, chè, bánh mì, hủ tiếu...). Đưa ra nhiều sự lựa chọn độc đáo.
6. Macros (P/C/F) ở từng món phải tính chuẩn xác thực tế.

Trả về JSON thuần túy, không có text dư thừa bọc ngoài:
{
  "meal_target_kcal": $mealCalTarget,
  "suggestions": [
    {
      "name": "Tên món ăn tiếng Việt (Combo nếu cần bù nhiều calo)",
      "name_en": "English name",
      "description": "Mô tả hấp dẫn, nhấn mạnh tại sao hợp mục tiêu",
      "calories": $mealCalTarget,
      "protein": 25,
      "carbs": 45,
      "fat": 12,
      "reason": "Giải thích nhanh sự phù hợp với calo còn lại"
    }
  ]
}''';

      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/v1/messages'),
            headers: {
              'x-api-key': _apiKey,
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
          .timeout(const Duration(seconds: 60));

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
    // Tính mục tiêu calo mỗi bữa
    int remainingMeals = 1;
    if (mealTime == 'breakfast') {
      remainingMeals = 3;
    } else if (mealTime == 'lunch') {
      remainingMeals = 2;
    } else if (mealTime == 'snack') {
      remainingMeals = 2;
    }
    double mealTarget = remainingCalories / remainingMeals;
    if (mealTarget < 150) {
      mealTarget = 150;
    }
    final double tolerance = 150; // ±150 kcal cho local fallback

    // Toàn bộ ngân hàng món ăn Việt Nam phân loại theo bữa + mục tiêu
    final allDishes = <MealSuggestion>[];

    if (mealTime == 'breakfast') {
      if (goal == 'lose') {
        allDishes.addAll([
          MealSuggestion(name: 'Cháo yến mạch với trái cây', nameEn: 'Oatmeal with fruits', description: 'Giàu chất xơ, no lâu', calories: 250, protein: 8, carbs: 45, fat: 5, reason: 'Ít calo, chất xơ cao'),
          MealSuggestion(name: 'Bánh mì trứng ốp la', nameEn: 'Bread with fried egg', description: 'Protein từ trứng', calories: 300, protein: 15, carbs: 35, fat: 10, reason: 'Protein buổi sáng, vừa đủ calo'),
          MealSuggestion(name: 'Cháo gà không dầu mỡ', nameEn: 'Chicken congee (low fat)', description: 'Nhẹ bụng, dễ tiêu', calories: 280, protein: 18, carbs: 38, fat: 4, reason: 'Protein cao, ít chất béo'),
          MealSuggestion(name: 'Trứng luộc + rau củ luộc', nameEn: 'Boiled eggs with vegetables', description: 'Sạch, ít dầu mỡ', calories: 220, protein: 14, carbs: 20, fat: 8, reason: 'Rất ít calo, giàu vitamin'),
          MealSuggestion(name: 'Sữa chua không đường + granola', nameEn: 'Sugar-free yogurt with granola', description: 'Probiotic tốt', calories: 240, protein: 12, carbs: 30, fat: 6, reason: 'Tốt đường ruột, ít calo'),
          MealSuggestion(name: 'Bánh cuốn không nhân', nameEn: 'Plain steamed rice rolls', description: 'Nhẹ, ít béo', calories: 200, protein: 5, carbs: 38, fat: 3, reason: 'Ít chất béo, dễ tiêu hóa'),
          MealSuggestion(name: 'Phở gà không da', nameEn: 'Chicken pho (skinless)', description: 'Protein từ ức gà', calories: 350, protein: 26, carbs: 42, fat: 7, reason: 'Protein cao, ít béo'),
          MealSuggestion(name: 'Bún riêu cua thanh đạm', nameEn: 'Light crab noodle soup', description: 'Mát, ít dầu mỡ', calories: 320, protein: 18, carbs: 46, fat: 6, reason: 'Ít calo, protein từ cua'),
          MealSuggestion(name: 'Cơm gạo lứt + trứng luộc', nameEn: 'Brown rice with boiled egg', description: 'Chất xơ cao', calories: 330, protein: 14, carbs: 52, fat: 7, reason: 'Chỉ số GI thấp, no lâu'),
          MealSuggestion(name: 'Sinh tố chuối yến mạch', nameEn: 'Banana oat smoothie', description: 'Uống nhanh buổi sáng', calories: 260, protein: 9, carbs: 48, fat: 4, reason: 'Dễ làm, cân bằng calo sáng'),
          // NEW: Additional breakfast dishes for weight loss
          MealSuggestion(name: 'Bánh mì đen + phô mai', nameEn: 'Black bread with cheese', description: ' Ít carbs, giàu canxi', calories: 230, protein: 10, carbs: 28, fat: 9, reason: 'GI thấp, no lâu'),
          MealSuggestion(name: 'Trứng gà áp chảo + rau mồng tơi', nameEn: 'Spinach scrambled eggs', description: 'Giàu sắt và vitamin', calories: 240, protein: 16, carbs: 6, fat: 16, reason: 'Protein cao, ít carbs'),
          MealSuggestion(name: 'Cháo đậu xanh', nameEn: 'Mung bean congee', description: 'Thanh mát, giải nhiệt', calories: 260, protein: 10, carbs: 45, fat: 4, reason: 'Chất xơ cao, ít calo'),
          MealSuggestion(name: 'Bánh da lợn', nameEn: 'Steamed tapioca cake', description: 'Truyền thống nhẹ', calories: 180, protein: 3, carbs: 38, fat: 2, reason: 'Ít calo, dễ tiêu'),
          MealSuggestion(name: 'Sữa chua phô mai', nameEn: 'Cream cheese yogurt', description: 'Probiotic + protein', calories: 150, protein: 12, carbs: 10, fat: 7, reason: 'Tốt cho tiêu hóa, ít calo'),
          MealSuggestion(name: 'Cháo nấm', nameEn: 'Mushroom congee', description: 'Thơm ngon,healthy', calories: 250, protein: 12, carbs: 40, fat: 5, reason: 'Ít calo, vitamin B'),
          MealSuggestion(name: 'Trứng cút luộc (5 quả)', nameEn: 'Boiled quail eggs x5', description: 'Protein mini', calories: 180, protein: 14, carbs: 2, fat: 12, reason: 'Protein cao, ít calo'),
          MealSuggestion(name: 'Bánh gai nướng', nameEn: 'Grilled black sesame cake', description: 'Truyền thống', calories: 200, protein: 5, carbs: 35, fat: 5, reason: 'Ít calo, giàu chất xơ'),
          MealSuggestion(name: 'Khoai môn luộc', nameEn: 'Boiled taro', description: 'Bột mịn, no lâu', calories: 210, protein: 3, carbs: 48, fat: 1, reason: 'GI trung bình, no lâu'),
          MealSuggestion(name: 'Cháo hạt sen', nameEn: 'Lotus seed congee', description: 'Mát, bổ dưỡng', calories: 270, protein: 8, carbs: 50, fat: 4, reason: 'Thanh nhiệt, dễ tiêu'),
        ]);
      } else if (goal == 'gain') {
        allDishes.addAll([
          MealSuggestion(name: 'Phở bò đặc biệt', nameEn: 'Special beef pho', description: 'Nhiều thịt bò', calories: 550, protein: 32, carbs: 60, fat: 18, reason: 'Protein cao, năng lượng dồi dào'),
          MealSuggestion(name: 'Xôi gà + trứng', nameEn: 'Sticky rice chicken egg', description: 'Năng lượng cao', calories: 620, protein: 28, carbs: 75, fat: 22, reason: 'Nhiều calo và protein'),
          MealSuggestion(name: 'Bánh mì pate thịt nguội', nameEn: 'Vietnamese baguette pate', description: 'Đầy đủ chất', calories: 480, protein: 20, carbs: 55, fat: 20, reason: 'Cân bằng macro, dễ ăn'),
          MealSuggestion(name: 'Bún bò Huế đặc biệt', nameEn: 'Hue beef noodle soup', description: 'Đặc sản miền Trung', calories: 580, protein: 30, carbs: 62, fat: 22, reason: 'Giàu protein, năng lượng'),
          MealSuggestion(name: 'Cơm tấm sườn bì chả', nameEn: 'Broken rice grilled pork', description: 'Món sáng Sài Gòn', calories: 650, protein: 35, carbs: 68, fat: 25, reason: 'Rất nhiều protein và calo'),
          MealSuggestion(name: 'Xôi lạp xưởng trứng cút', nameEn: 'Sticky rice sausage quail egg', description: 'Đậm đà, đủ chất', calories: 600, protein: 22, carbs: 72, fat: 24, reason: 'Calo cao cho tăng cân'),
          MealSuggestion(name: 'Bánh ướt thịt nướng', nameEn: 'Steamed rice crepe grilled pork', description: 'Cuốn thịt phong phú', calories: 520, protein: 26, carbs: 58, fat: 18, reason: 'Năng lượng và protein cao'),
          MealSuggestion(name: 'Mì Quảng gà thịt heo', nameEn: 'Quang noodle chicken pork', description: 'Đặc sản Đà Nẵng', calories: 570, protein: 30, carbs: 65, fat: 18, reason: 'Đủ macro, nhiều năng lượng'),
          // NEW: Additional breakfast dishes for weight gain
          MealSuggestion(name: 'Bánh mì chả cá', nameEn: 'Fish cake baguette', description: 'Giòn, nhiều nhân', calories: 520, protein: 24, carbs: 56, fat: 22, reason: 'Protein từ cá, calo cao'),
          MealSuggestion(name: 'Xôi đậu phộng', nameEn: 'Peanut sticky rice', description: 'Béo bùi, thơm', calories: 550, protein: 18, carbs: 70, fat: 22, reason: 'Chất béo thực vật cao'),
          MealSuggestion(name: 'Bánh mì xúc xích', nameEn: 'Sausage baguette', description: 'Tiện lợi, no', calories: 490, protein: 18, carbs: 52, fat: 24, reason: 'Calo cao, dễ ăn'),
          MealSuggestion(name: 'Mì trứng gà xào', nameEn: 'Egg chicken stir-fry noodles', description: 'Đủ đạm và carb', calories: 580, protein: 28, carbs: 60, fat: 24, reason: 'Năng lượng cho buổi sáng'),
          MealSuggestion(name: 'Cháo thịt bắp bò', nameEn: 'Beef shank congee', description: 'Bổ dưỡng, đặc', calories: 480, protein: 30, carbs: 50, fat: 18, reason: 'Protein cao từ thịt bò'),
          MealSuggestion(name: 'Bánh bao nhân thịt', nameEn: 'Steamed pork buns', description: 'Nhà làm, đầy đặn', calories: 460, protein: 18, carbs: 58, fat: 18, reason: 'Calo cao, tiện lợi'),
          MealSuggestion(name: 'Xôi ngô', nameEn: 'Corn sticky rice', description: 'Ngọt tự nhiên', calories: 480, protein: 14, carbs: 68, fat: 16, reason: 'Carbs phức hợp, no lâu'),
          MealSuggestion(name: 'Bánh giò', nameEn: 'Vietnamese pork pie', description: 'Truyền thống Hà Nội', calories: 420, protein: 16, carbs: 48, fat: 18, reason: 'Năng lượng ổn định'),
          MealSuggestion(name: 'Bánh tổ', nameEn: 'Coconut candy', description: 'Ngọt, béo', calories: 380, protein: 6, carbs: 45, fat: 20, reason: 'Năng lượng nhanh'),
          MealSuggestion(name: 'Cháo vịt', nameEn: 'Duck congee', description: 'Đậm đà, bổ', calories: 520, protein: 28, carbs: 55, fat: 20, reason: 'Protein cao, ấm bụng'),
        ]);
      } else {
        allDishes.addAll([
          MealSuggestion(name: 'Phở gà', nameEn: 'Chicken pho', description: 'Nhẹ nhàng, cân bằng', calories: 420, protein: 24, carbs: 52, fat: 12, reason: 'Cân bằng dinh dưỡng, dễ tiêu'),
          MealSuggestion(name: 'Bánh cuốn nhân thịt', nameEn: 'Steamed rice rolls pork', description: 'Mềm mại, thơm ngon', calories: 380, protein: 18, carbs: 48, fat: 14, reason: 'Vừa đủ năng lượng'),
          MealSuggestion(name: 'Hủ tiếu Nam Vang', nameEn: 'Phnom Penh noodle soup', description: 'Thanh đạm, ngon', calories: 400, protein: 22, carbs: 50, fat: 12, reason: 'Đủ chất, không nặng bụng'),
          MealSuggestion(name: 'Xôi xéo', nameEn: 'Sticky rice mung bean', description: 'Truyền thống Hà Nội', calories: 450, protein: 15, carbs: 62, fat: 16, reason: 'Năng lượng ổn định sáng'),
          MealSuggestion(name: 'Bún riêu cua', nameEn: 'Crab noodle soup', description: 'Thanh mát, bổ dưỡng', calories: 410, protein: 20, carbs: 54, fat: 11, reason: 'Protein từ cua, cân bằng'),
          MealSuggestion(name: 'Bánh mì heo quay', nameEn: 'Baguette roast pork', description: 'Giòn thơm', calories: 460, protein: 22, carbs: 50, fat: 18, reason: 'Cân bằng macro, no lâu'),
          MealSuggestion(name: 'Cháo thịt bằm', nameEn: 'Pork minced congee', description: 'Ấm bụng, bổ dưỡng', calories: 370, protein: 20, carbs: 48, fat: 10, reason: 'Dễ tiêu, đủ calo sáng'),
          MealSuggestion(name: 'Bún mọc', nameEn: 'Pork ball noodle soup', description: 'Thanh ngọt nước dùng', calories: 390, protein: 22, carbs: 50, fat: 11, reason: 'Protein vừa đủ, calo cân'),
          MealSuggestion(name: 'Xôi gà', nameEn: 'Sticky rice with chicken', description: 'Đủ đạm và tinh bột', calories: 480, protein: 26, carbs: 60, fat: 14, reason: 'Protein + carbs cân bằng'),
          // NEW: Additional breakfast dishes for maintenance
          MealSuggestion(name: 'Bánh mì bơ tỏi', nameEn: 'Butter garlic bread', description: 'Thơm giòn', calories: 400, protein: 10, carbs: 48, fat: 18, reason: 'Năng lượng vừa đủ'),
          MealSuggestion(name: 'Mì gà trứng', nameEn: 'Chicken egg noodles', description: 'Đủ chất', calories: 440, protein: 26, carbs: 50, fat: 16, reason: 'Cân bằng dinh dưỡng'),
          MealSuggestion(name: 'Cháo lòng', nameEn: 'Pork organ congee', description: 'Đậm đà, bổ', calories: 380, protein: 22, carbs: 42, fat: 14, reason: 'Giàu sắt, protein'),
          MealSuggestion(name: 'Bánh đúc', nameEn: 'Rice flour cake', description: 'Mịn, nhẹ', calories: 320, protein: 8, carbs: 60, fat: 6, reason: 'Dễ tiêu, ít béo'),
          MealSuggestion(name: 'Bánh cốm', nameEn: 'Green rice cake', description: 'Mùa thu Hà Nội', calories: 360, protein: 10, carbs: 55, fat: 12, reason: 'Truyền thống, năng lượng'),
          MealSuggestion(name: 'Xôi sầu riêng', nameEn: 'Durian sticky rice', description: 'Béo ngọt đặc biệt', calories: 520, protein: 14, carbs: 65, fat: 24, reason: 'Năng lượng cao'),
          MealSuggestion(name: 'Bánh pía', nameEn: 'Pia cake', description: 'Đặc sản Sài Gòn', calories: 380, protein: 10, carbs: 55, fat: 14, reason: 'Năng lượng, ngon miệng'),
          MealSuggestion(name: 'Cháo cá', nameEn: 'Fish congee', description: 'Thanh, bổ', calories: 340, protein: 22, carbs: 42, fat: 8, reason: 'Protein từ cá, nhẹ'),
          MealSuggestion(name: 'Hủ tiếu xào', nameEn: 'Stir-fried rice noodles', description: 'Giòn, thơm', calories: 450, protein: 18, carbs: 58, fat: 16, reason: 'Carbs + protein vừa'),
          MealSuggestion(name: 'Bánh khọt', nameEn: 'Mini shrimp pancakes', description: 'Giòn tan', calories: 390, protein: 16, carbs: 42, fat: 18, reason: 'Hải sản, đa dạng'),
        ]);
      }
    } else if (mealTime == 'lunch') {
      if (goal == 'lose') {
        allDishes.addAll([
          MealSuggestion(name: 'Cơm gạo lứt cá hấp', nameEn: 'Brown rice steamed fish', description: 'Ít calo, nhiều protein', calories: 400, protein: 30, carbs: 45, fat: 10, reason: 'Protein cao, ít chất béo'),
          MealSuggestion(name: 'Bún chả cá', nameEn: 'Fish cake noodle soup', description: 'Nhẹ nhàng, dễ tiêu', calories: 350, protein: 22, carbs: 40, fat: 8, reason: 'Ít calo nhưng no bụng'),
          MealSuggestion(name: 'Salad gà nướng', nameEn: 'Grilled chicken salad', description: 'Nhiều rau xanh', calories: 320, protein: 28, carbs: 18, fat: 12, reason: 'Rất ít calo, vitamin cao'),
          MealSuggestion(name: 'Canh chua cá + cơm gạo lứt', nameEn: 'Sour fish soup brown rice', description: 'Thanh mát, ít dầu', calories: 380, protein: 26, carbs: 42, fat: 9, reason: 'Ít béo, nhiều vitamin C'),
          MealSuggestion(name: 'Gỏi cuốn tôm thịt (4 cuốn)', nameEn: 'Fresh spring rolls', description: 'Tươi mát, không chiên', calories: 340, protein: 20, carbs: 38, fat: 10, reason: 'Sạch, không dầu mỡ'),
          MealSuggestion(name: 'Cơm ức gà hấp xốt', nameEn: 'Steamed chicken breast rice', description: 'Protein tinh nạc', calories: 380, protein: 36, carbs: 40, fat: 7, reason: 'Tinh nạc, rất ít béo'),
          MealSuggestion(name: 'Súp lơ xào tôm + cơm', nameEn: 'Broccoli shrimp stir-fry rice', description: 'Nhiều rau, ít dầu', calories: 360, protein: 24, carbs: 44, fat: 8, reason: 'Chất xơ cao, ít calo'),
          MealSuggestion(name: 'Bún bò xào rau củ', nameEn: 'Stir-fried beef rice noodles', description: 'Nhẹ, đủ protein', calories: 400, protein: 26, carbs: 48, fat: 10, reason: 'Cân bằng, ít béo'),
          MealSuggestion(name: 'Cơm tấm sườn nướng (nhỏ)', nameEn: 'Small broken rice grilled pork', description: 'Kiểm soát khẩu phần', calories: 420, protein: 28, carbs: 44, fat: 12, reason: 'Kiểm soát calo bữa trưa'),
          MealSuggestion(name: 'Miến gà rau thơm', nameEn: 'Chicken glass noodle herbs', description: 'No lâu, ít tinh bột', calories: 330, protein: 22, carbs: 38, fat: 8, reason: 'GI thấp, no không béo'),
          // NEW: Additional lunch dishes for weight loss
          MealSuggestion(name: 'Cơm trắng + cá thát lát chiên', nameEn: 'Fish fry rice', description: 'Protein từ cá', calories: 390, protein: 28, carbs: 48, fat: 10, reason: 'Ít calo, protein cao'),
          MealSuggestion(name: 'Bún mọc chả', nameEn: 'Pork ball noodle soup', description: 'Thanh, đủ đạm', calories: 380, protein: 24, carbs: 45, fat: 10, reason: 'Cân bằng dinh dưỡng'),
          MealSuggestion(name: 'Salad rau mầm', nameEn: 'Sprout salad', description: 'Giàu vitamin', calories: 180, protein: 8, carbs: 20, fat: 8, reason: 'Rất ít calo, vitamin cao'),
          MealSuggestion(name: 'Cơm gạo lứt thịt bò xào', nameEn: 'Brown rice beef stir-fry', description: 'Giàu sắt', calories: 420, protein: 30, carbs: 48, fat: 12, reason: 'Protein + chất xơ'),
          MealSuggestion(name: 'Bánh căn tôm', nameEn: 'Shrimp rice pancakes', description: 'Giòn, ít béo', calories: 340, protein: 18, carbs: 40, fat: 10, reason: 'Hải sản, ít calo'),
          MealSuggestion(name: 'Gỏi đu đủ tôm khô', nameEn: 'Papaya shrimp salad', description: 'Chua ngọt', calories: 290, protein: 16, carbs: 35, fat: 8, reason: 'Tiêu hóa tốt'),
          MealSuggestion(name: 'Cơm nấm hải sản', nameEn: 'Mushroom seafood rice', description: 'Thơm, healthy', calories: 380, protein: 22, carbs: 52, fat: 10, reason: 'Thực vật + hải sản'),
          MealSuggestion(name: 'Bún năng lọc', nameEn: 'Seaweed vermicelli', description: 'Ít calo, giàu i-ốt', calories: 320, protein: 14, carbs: 48, fat: 6, reason: 'Giàu khoáng chất'),
          MealSuggestion(name: 'Cháo yến mạch thịt bằm', nameEn: 'Oatmeal pork congee', description: 'Giàu chất xơ', calories: 310, protein: 18, carbs: 42, fat: 8, reason: 'Chất xơ cao, no lâu'),
          MealSuggestion(name: 'Cơm gà luộc', nameEn: 'Steamed chicken rice', description: 'Nhẹ, protein cao', calories: 360, protein: 32, carbs: 42, fat: 8, reason: 'Tinh nạc, ít béo'),
        ]);
      } else if (goal == 'gain') {
        allDishes.addAll([
          MealSuggestion(name: 'Cơm sườn nướng + trứng', nameEn: 'Grilled pork chop rice egg', description: 'Thơm ngon, đủ chất', calories: 720, protein: 40, carbs: 70, fat: 28, reason: 'Protein và calo cao'),
          MealSuggestion(name: 'Bún bò Huế đặc biệt', nameEn: 'Special Hue beef noodle', description: 'Nhiều thịt, giò heo', calories: 680, protein: 38, carbs: 65, fat: 26, reason: 'Giàu protein từ thịt và giò'),
          MealSuggestion(name: 'Cơm gà xối mỡ', nameEn: 'Hoi An chicken rice', description: 'Đặc sản Hội An', calories: 650, protein: 35, carbs: 68, fat: 24, reason: 'Nhiều calo và protein'),
          MealSuggestion(name: 'Mì Quảng thịt heo', nameEn: 'Quang noodles pork', description: 'Đặc sản miền Trung', calories: 620, protein: 32, carbs: 72, fat: 22, reason: 'Đầy đủ dinh dưỡng'),
          MealSuggestion(name: 'Cơm chiên dương châu', nameEn: 'Yangzhou fried rice', description: 'Nhiều topping', calories: 700, protein: 30, carbs: 80, fat: 28, reason: 'Calo cao, đa dạng dinh dưỡng'),
          MealSuggestion(name: 'Cơm niêu cá kho tộ', nameEn: 'Clay pot braised fish rice', description: 'Đậm đà truyền thống', calories: 660, protein: 36, carbs: 68, fat: 24, reason: 'Protein cá + năng lượng cao'),
          MealSuggestion(name: 'Bánh mì thịt nguội đặc biệt', nameEn: 'Special cold cut baguette', description: 'Nhiều nhân', calories: 580, protein: 28, carbs: 62, fat: 22, reason: 'Calo dồi dào, protein cao'),
          MealSuggestion(name: 'Bún bò nam bộ', nameEn: 'Southern beef vermicelli', description: 'Tươi mát, nhiều topping', calories: 600, protein: 34, carbs: 66, fat: 18, reason: 'Protein từ bò, năng lượng tốt'),
          MealSuggestion(name: 'Cơm tấm bì chả + trứng', nameEn: 'Broken rice pork skin egg', description: 'Combo đầy đủ', calories: 730, protein: 42, carbs: 72, fat: 28, reason: 'Calo và protein tối ưu tăng cân'),
          // NEW: Additional lunch dishes for weight gain
          MealSuggestion(name: 'Bún chả Hà Nội', nameEn: 'Hanoi grilled pork noodles', description: 'Nhiều chả', calories: 620, protein: 32, carbs: 68, fat: 24, reason: 'Protein + calo cao'),
          MealSuggestion(name: 'Bánh xèo tôm thịt', nameEn: 'Savory pancake shrimp pork', description: 'Giòn, đầy nhân', calories: 580, protein: 26, carbs: 55, fat: 28, reason: 'Năng lượng cao'),
          MealSuggestion(name: 'Cơm gà rán', nameEn: 'Fried chicken rice', description: 'Giòn vàng', calories: 680, protein: 36, carbs: 70, fat: 28, reason: 'Calo cao, protein gà'),
          MealSuggestion(name: 'Lẩu bò', nameEn: 'Beef hotpot', description: 'Nhiều thịt bò', calories: 700, protein: 45, carbs: 50, fat: 30, reason: 'Protein bò rất cao'),
          MealSuggestion(name: 'Cơm sườn ram', nameEn: 'Braised pork rib rice', description: 'Đậm đà', calories: 650, protein: 34, carbs: 65, fat: 26, reason: 'Năng lượng dồi dào'),
          MealSuggestion(name: 'Bún bò xào', nameEn: 'Stir-fried beef noodles', description: 'Đậm đà', calories: 590, protein: 30, carbs: 60, fat: 24, reason: 'Calo + protein bò'),
          MealSuggestion(name: 'Mì vịt tiềm', nameEn: 'Braised duck noodles', description: 'Đặc sản', calories: 640, protein: 35, carbs: 58, fat: 28, reason: 'Protein từ vịt'),
          MealSuggestion(name: 'Cơm cá rang', nameEn: 'Fried fish rice', description: 'Nhiều cá', calories: 600, protein: 36, carbs: 62, fat: 22, reason: 'Protein cá cao'),
          MealSuggestion(name: 'Bánh mì kẹp thịt nướng', nameEn: 'Grilled pork baguette', description: 'Đầy đặn', calories: 560, protein: 28, carbs: 55, fat: 24, reason: 'Calo cho bữa trưa'),
          MealSuggestion(name: 'Xôi đậu xanh trứng', nameEn: 'Mung bean sticky rice egg', description: 'Béo bùi', calories: 550, protein: 22, carbs: 72, fat: 20, reason: 'Năng lượng cao'),
        ]);
      } else {
        allDishes.addAll([
          MealSuggestion(name: 'Cơm rang thập cẩm', nameEn: 'Mixed fried rice', description: 'Đa dạng nguyên liệu', calories: 520, protein: 24, carbs: 62, fat: 18, reason: 'Cân bằng, đủ chất'),
          MealSuggestion(name: 'Bún chả Hà Nội', nameEn: 'Hanoi grilled pork noodles', description: 'Đặc sản Hà thành', calories: 480, protein: 26, carbs: 55, fat: 16, reason: 'Protein từ thịt nướng'),
          MealSuggestion(name: 'Cơm gà Hải Nam', nameEn: 'Hainanese chicken rice', description: 'Thơm ngon, bổ dưỡng', calories: 500, protein: 28, carbs: 58, fat: 16, reason: 'Đủ năng lượng, không quá nặng'),
          MealSuggestion(name: 'Phở bò tái', nameEn: 'Rare beef pho', description: 'Món truyền thống', calories: 460, protein: 26, carbs: 56, fat: 14, reason: 'Cân bằng macro, dễ tiêu'),
          MealSuggestion(name: 'Cơm tấm sườn nướng', nameEn: 'Broken rice grilled pork', description: 'Món miền Nam', calories: 540, protein: 30, carbs: 60, fat: 20, reason: 'Đầy đủ dinh dưỡng'),
          MealSuggestion(name: 'Bún thịt nướng', nameEn: 'Grilled pork vermicelli', description: 'Thanh mát, thơm lừng', calories: 470, protein: 25, carbs: 55, fat: 15, reason: 'Đủ chất, không quá nặng'),
          MealSuggestion(name: 'Cơm cá kho tiêu', nameEn: 'Braised fish pepper rice', description: 'Đậm đà truyền thống', calories: 500, protein: 30, carbs: 54, fat: 16, reason: 'Protein từ cá, cân bằng'),
          MealSuggestion(name: 'Mì vịt tiềm', nameEn: 'Braised duck egg noodles', description: 'Đặc sản Sài Gòn', calories: 510, protein: 28, carbs: 58, fat: 16, reason: 'Vừa đủ calo, protein cao'),
          MealSuggestion(name: 'Bún bò xả ớt', nameEn: 'Lemongrass beef vermicelli', description: 'Thơm nồng, cay nhẹ', calories: 490, protein: 28, carbs: 54, fat: 16, reason: 'Calo vừa, protein bò cao'),
          MealSuggestion(name: 'Cơm gà chiên nước mắm', nameEn: 'Fish sauce fried chicken rice', description: 'Giòn vàng thơm', calories: 530, protein: 32, carbs: 56, fat: 18, reason: 'Cân bằng tốt, protein cao'),
          MealSuggestion(name: 'Bánh xèo + rau sống', nameEn: 'Crispy pancake fresh herbs', description: 'Giòn tan, tươi mát', calories: 480, protein: 20, carbs: 52, fat: 20, reason: 'Đa dạng, đủ vi chất'),
          // NEW: Additional lunch dishes for maintenance
          MealSuggestion(name: 'Cơm rang cua', nameEn: 'Crab fried rice', description: 'Nhiều cua', calories: 540, protein: 28, carbs: 60, fat: 18, reason: 'Protein từ cua'),
          MealSuggestion(name: 'Bún bò lúc lắc', nameEn: 'Shaking beef vermicelli', description: 'Bò Úc', calories: 520, protein: 32, carbs: 55, fat: 20, reason: 'Protein bò cao'),
          MealSuggestion(name: 'Cơm gà om tuyến', nameEn: 'Chicken gland rice', description: 'Bổ dưỡng', calories: 560, protein: 34, carbs: 58, fat: 20, reason: 'Nhiều dinh dưỡng'),
          MealSuggestion(name: 'Mì xào hải sản', nameEn: 'Seafood stir-fry noodles', description: 'Phong phú', calories: 510, protein: 26, carbs: 60, fat: 18, reason: 'Hải sản + carbs'),
          MealSuggestion(name: 'Bánh đúc nhân thịt', nameEn: 'Pork stuffed cake', description: 'Truyền thống', calories: 450, protein: 20, carbs: 52, fat: 16, reason: 'Cân bằng'),
          MealSuggestion(name: 'Cơm tấm chả trứng', nameEn: 'Broken rice egg cake', description: 'Combo Sài Gòn', calories: 560, protein: 30, carbs: 62, fat: 20, reason: 'Đủ chất, ngon'),
          MealSuggestion(name: 'Bún mọc nạc', nameEn: 'Lean pork ball noodles', description: 'Ít mỡ', calories: 420, protein: 26, carbs: 50, fat: 12, reason: 'Protein, ít béo'),
          MealSuggestion(name: 'Cơm chiên cá mặn', nameEn: 'Salted fish fried rice', description: 'Đậm đà', calories: 500, protein: 24, carbs: 58, fat: 20, reason: 'Hương vị truyền thống'),
          MealSuggestion(name: 'Phở gà tái', nameEn: 'Rare chicken pho', description: 'Nhẹ hơn bò', calories: 400, protein: 26, carbs: 48, fat: 12, reason: 'Protein gà, dễ tiêu'),
          MealSuggestion(name: 'Bánh bèo', nameEn: 'Water fern cakes', description: 'Đặc sản Huế', calories: 380, protein: 14, carbs: 50, fat: 14, reason: 'Truyền thống, vừa calo'),
        ]);
      }
    } else if (mealTime == 'dinner') {
      if (goal == 'lose') {
        allDishes.addAll([
          MealSuggestion(name: 'Canh rau củ + cá hấp', nameEn: 'Vegetable soup steamed fish', description: 'Nhẹ bụng, dễ ngủ', calories: 320, protein: 28, carbs: 30, fat: 8, reason: 'Ít calo, không nặng bụng tối'),
          MealSuggestion(name: 'Gỏi ngó sen tôm thịt', nameEn: 'Lotus root shrimp salad', description: 'Giòn ngon, thanh mát', calories: 280, protein: 22, carbs: 28, fat: 9, reason: 'Ít calo, nhiều chất xơ'),
          MealSuggestion(name: 'Súp gà nấm', nameEn: 'Chicken mushroom soup', description: 'Ấm bụng, bổ dưỡng', calories: 260, protein: 24, carbs: 20, fat: 8, reason: 'Protein cao, ít carbs'),
          MealSuggestion(name: 'Đậu hũ sốt cà chua + cơm', nameEn: 'Tofu tomato sauce rice', description: 'Chay nhẹ, healthy', calories: 340, protein: 18, carbs: 48, fat: 10, reason: 'Protein thực vật, ít calo'),
          MealSuggestion(name: 'Bún rau luộc + tôm', nameEn: 'Boiled vegetable noodles shrimp', description: 'Sạch, ít dầu mỡ', calories: 300, protein: 20, carbs: 36, fat: 6, reason: 'Rất ít chất béo'),
          MealSuggestion(name: 'Cháo bí đỏ tôm', nameEn: 'Pumpkin shrimp congee', description: 'Ngọt dịu, nhẹ bụng', calories: 270, protein: 18, carbs: 38, fat: 5, reason: 'Ít calo, no lâu ban đêm'),
          MealSuggestion(name: 'Cá hồi áp chảo + salad', nameEn: 'Pan-seared salmon salad', description: 'Omega-3 lành mạnh', calories: 350, protein: 32, carbs: 12, fat: 18, reason: 'Chất béo tốt, protein cao'),
          MealSuggestion(name: 'Gỏi bắp cải gà xé', nameEn: 'Cabbage shredded chicken salad', description: 'Tươi giòn, ít dầu', calories: 290, protein: 26, carbs: 24, fat: 8, reason: 'Ít calo, nhiều protein'),
          MealSuggestion(name: 'Canh khổ qua nhồi thịt', nameEn: 'Stuffed bitter melon soup', description: 'Mát, giải nhiệt', calories: 310, protein: 22, carbs: 28, fat: 10, reason: 'Ít calo, detox tốt'),
          // NEW: Additional dinner dishes for weight loss
          MealSuggestion(name: 'Cơm trắng + cá thu hấp', nameEn: 'Steamed mackerel rice', description: 'Omega-3 cao', calories: 340, protein: 26, carbs: 40, fat: 8, reason: 'Protein cá, ít calo'),
          MealSuggestion(name: 'Salad ức gà', nameEn: 'Chicken breast salad', description: 'Protein tinh nạc', calories: 280, protein: 32, carbs: 15, fat: 10, reason: 'Rất ít calo, protein cao'),
          MealSuggestion(name: 'Canh chua cá lóc', nameEn: 'Snakehead fish sour soup', description: 'Thanh, mát', calories: 300, protein: 24, carbs: 28, fat: 8, reason: 'Ít calo, vitamin C'),
          MealSuggestion(name: 'Bún nấu chua', nameEn: 'Sour noodle soup', description: 'Chua ngọt', calories: 340, protein: 20, carbs: 45, fat: 8, reason: 'Tiêu hóa tốt'),
          MealSuggestion(name: 'Cơm gạo lứt + thịt bò xào', nameEn: 'Brown rice beef stir-fry', description: 'Giàu sắt', calories: 360, protein: 26, carbs: 42, fat: 10, reason: 'Protein + chất xơ'),
          MealSuggestion(name: 'Súp bí đỏ', nameEn: 'Pumpkin soup', description: 'Ngọt dịu', calories: 200, protein: 8, carbs: 30, fat: 5, reason: 'Rất ít calo'),
          MealSuggestion(name: 'Gỏi su su', nameEn: 'Chayote salad', description: 'Giòn, mát', calories: 180, protein: 6, carbs: 25, fat: 6, reason: 'Ít calo, vitamin'),
          MealSuggestion(name: 'Đậu hũ luộc + nước tương', nameEn: 'Steamed tofu soy sauce', description: 'Chay nhẹ', calories: 220, protein: 16, carbs: 10, fat: 12, reason: 'Protein thực vật'),
          MealSuggestion(name: 'Rau muống xào tỏi', nameEn: 'Water spinach garlic stir-fry', description: 'Xanh,healthy', calories: 150, protein: 8, carbs: 12, fat: 8, reason: 'Rất ít calo'),
          MealSuggestion(name: 'Cháo hạt sen', nameEn: 'Lotus seed congee', description: 'Mát, bổ', calories: 260, protein: 10, carbs: 45, fat: 4, reason: 'Dễ tiêu, ít calo'),
        ]);
      } else if (goal == 'gain') {
        allDishes.addAll([
          MealSuggestion(name: 'Lẩu thái hải sản', nameEn: 'Thai seafood hotpot', description: 'Nhiều hải sản', calories: 620, protein: 42, carbs: 50, fat: 24, reason: 'Protein cao từ hải sản'),
          MealSuggestion(name: 'Cơm niêu sườn ram', nameEn: 'Clay pot braised ribs rice', description: 'Thơm lừng, đậm đà', calories: 680, protein: 36, carbs: 72, fat: 26, reason: 'Nhiều năng lượng và protein'),
          MealSuggestion(name: 'Bún đậu mắm tôm', nameEn: 'Tofu noodle shrimp paste', description: 'Đặc sản Hà Nội', calories: 650, protein: 32, carbs: 68, fat: 28, reason: 'Calo cao, protein đậu thịt'),
          MealSuggestion(name: 'Cơm gà rán + khoai tây chiên', nameEn: 'Fried chicken rice fries', description: 'Giòn rụm, thơm ngon', calories: 720, protein: 38, carbs: 75, fat: 30, reason: 'Rất nhiều calo và protein'),
          MealSuggestion(name: 'Bánh xèo tôm thịt', nameEn: 'Vietnamese savory pancake', description: 'Giòn tan, đầy nhân', calories: 580, protein: 28, carbs: 60, fat: 26, reason: 'Nhiều protein và năng lượng'),
          MealSuggestion(name: 'Thịt bò nướng lá lốt + cơm', nameEn: 'Beef betel leaf BBQ rice', description: 'Thơm cay đặc biệt', calories: 640, protein: 38, carbs: 64, fat: 24, reason: 'Protein bò cao, calo dồi dào'),
          MealSuggestion(name: 'Cháo thịt bắp bò đặc', nameEn: 'Thick beef shank congee', description: 'Đặc sệt, bổ dưỡng', calories: 560, protein: 34, carbs: 62, fat: 18, reason: 'Calo tốt cho phục hồi cơ'),
          MealSuggestion(name: 'Cơm tôm nướng + trứng chiên', nameEn: 'Grilled shrimp rice fried egg', description: 'Đủ topping phong phú', calories: 670, protein: 40, carbs: 68, fat: 24, reason: 'Combo protein cao tăng cân'),
          // NEW: Additional dinner dishes for weight gain
          MealSuggestion(name: 'Lẩu bò', nameEn: 'Beef hotpot', description: 'Nhiều thịt bò', calories: 680, protein: 45, carbs: 45, fat: 30, reason: 'Protein bò rất cao'),
          MealSuggestion(name: 'Cơm gà xối mỡ', nameEn: 'Chicken rice fat', description: 'Béo, ngọt', calories: 620, protein: 35, carbs: 60, fat: 28, reason: 'Calo cao'),
          MealSuggestion(name: 'Bún bò Huế', nameEn: 'Hue beef noodle', description: 'Đậm đà', calories: 600, protein: 32, carbs: 58, fat: 24, reason: 'Năng lượng cao'),
          MealSuggestion(name: 'Cơm chiên hải sản', nameEn: 'Seafood fried rice', description: 'Nhiều topping', calories: 650, protein: 32, carbs: 70, fat: 26, reason: 'Hải sản + calo'),
          MealSuggestion(name: 'Thịt heo quay + cơm', nameEn: 'Roast pork rice', description: 'Giòn, béo', calories: 620, protein: 34, carbs: 55, fat: 28, reason: 'Protein + calo'),
          MealSuggestion(name: 'Mì xào bò', nameEn: 'Beef stir-fry noodles', description: 'Đậm đà', calories: 580, protein: 30, carbs: 55, fat: 24, reason: 'Calo + protein bò'),
          MealSuggestion(name: 'Cơm cá kho + trứng', nameEn: 'Braised fish egg rice', description: 'Truyền thống', calories: 580, protein: 32, carbs: 60, fat: 22, reason: 'Protein cá cao'),
          MealSuggestion(name: 'Bánh xèo nhân thịt', nameEn: 'Pork savory pancake', description: 'Giòn, nhiều nhân', calories: 560, protein: 26, carbs: 52, fat: 26, reason: 'Năng lượng tối'),
          MealSuggestion(name: 'Lẩu gà', nameEn: 'Chicken hotpot', description: 'Nhiều thịt gà', calories: 600, protein: 38, carbs: 45, fat: 28, reason: 'Protein gà cao'),
          MealSuggestion(name: 'Cơm niêu thịt kho', nameEn: 'Clay pot braised pork rice', description: 'Đậm đà', calories: 620, protein: 32, carbs: 65, fat: 26, reason: 'Calo tối'),
        ]);
      } else {
        allDishes.addAll([
          MealSuggestion(name: 'Cơm rang dưa bò', nameEn: 'Fried rice pickled veg beef', description: 'Đơn giản, ngon miệng', calories: 480, protein: 26, carbs: 56, fat: 16, reason: 'Cân bằng, dễ tiêu hóa'),
          MealSuggestion(name: 'Bún thịt nướng', nameEn: 'Grilled pork vermicelli', description: 'Thanh mát, thơm lừng', calories: 460, protein: 24, carbs: 54, fat: 16, reason: 'Đủ chất, không quá nặng'),
          MealSuggestion(name: 'Cá kho tộ + cơm', nameEn: 'Braised fish clay pot rice', description: 'Đậm đà truyền thống', calories: 500, protein: 30, carbs: 52, fat: 18, reason: 'Protein từ cá, cân bằng'),
          MealSuggestion(name: 'Miến gà', nameEn: 'Chicken glass noodle soup', description: 'Nhẹ nhàng, bổ dưỡng', calories: 420, protein: 22, carbs: 48, fat: 14, reason: 'Dễ tiêu, không nặng bụng'),
          MealSuggestion(name: 'Cơm cá thu kho', nameEn: 'Braised mackerel rice', description: 'Giàu omega-3', calories: 510, protein: 28, carbs: 54, fat: 20, reason: 'Chất béo lành mạnh từ cá'),
          MealSuggestion(name: 'Đậu hũ non hấp trứng', nameEn: 'Steamed tofu with egg', description: 'Thanh đạm, bổ dưỡng', calories: 380, protein: 22, carbs: 28, fat: 18, reason: 'Protein thực vật + trứng'),
          MealSuggestion(name: 'Canh chua tôm + cơm trắng', nameEn: 'Sour shrimp soup white rice', description: 'Thanh ngọt đặc trưng', calories: 450, protein: 24, carbs: 56, fat: 12, reason: 'Cân bằng calo bữa tối'),
          MealSuggestion(name: 'Bò xào rau củ + cơm', nameEn: 'Stir-fried beef vegetables rice', description: 'Đầy màu sắc dinh dưỡng', calories: 490, protein: 30, carbs: 54, fat: 14, reason: 'Protein bò, vitamin rau củ'),
          MealSuggestion(name: 'Cơm gà kho gừng', nameEn: 'Ginger braised chicken rice', description: 'Ấm bụng, thơm gừng', calories: 470, protein: 28, carbs: 52, fat: 14, reason: 'Vừa đủ calo tối'),
          MealSuggestion(name: 'Canh bí đao giò sống + cơm', nameEn: 'Winter melon pork soup rice', description: 'Mát, giải nhiệt', calories: 440, protein: 24, carbs: 52, fat: 14, reason: 'Nhẹ nhàng, cân bằng'),
          // NEW: Additional dinner dishes for maintenance
          MealSuggestion(name: 'Cơm rang cua', nameEn: 'Crab fried rice', description: 'Nhiều cua', calories: 500, protein: 26, carbs: 55, fat: 18, reason: 'Protein từ cua'),
          MealSuggestion(name: 'Bún bò lúc lắc', nameEn: 'Shaking beef vermicelli', description: 'Bò Úc', calories: 510, protein: 32, carbs: 52, fat: 20, reason: 'Protein bò cao'),
          MealSuggestion(name: 'Cơm gà om tuyến', nameEn: 'Chicken gland rice', description: 'Bổ dưỡng', calories: 520, protein: 30, carbs: 56, fat: 18, reason: 'Nhiều dinh dưỡng'),
          MealSuggestion(name: 'Mì xào hải sản', nameEn: 'Seafood stir-fry noodles', description: 'Phong phú', calories: 480, protein: 24, carbs: 55, fat: 18, reason: 'Hải sản + carbs'),
          MealSuggestion(name: 'Cá lóc kho tộ', nameEn: 'Clay pot braised snakehead', description: 'Đậm đà', calories: 480, protein: 30, carbs: 45, fat: 18, reason: 'Protein cá'),
          MealSuggestion(name: 'Bún chả cá', nameEn: 'Fish cake noodle soup', description: 'Thanh, ngon', calories: 440, protein: 24, carbs: 52, fat: 14, reason: 'Cân bằng'),
          MealSuggestion(name: 'Cơm tấm chả trứng', nameEn: 'Broken rice egg cake', description: 'Combo Sài Gòn', calories: 520, protein: 28, carbs: 58, fat: 18, reason: 'Đủ chất'),
          MealSuggestion(name: 'Gỏi gà', nameEn: 'Chicken salad', description: 'Tươi mát', calories: 380, protein: 28, carbs: 30, fat: 14, reason: 'Protein gà, ít calo'),
          MealSuggestion(name: 'Canh cải xào đậu hũ', nameEn: 'Tofu vegetable soup', description: 'Chay nhẹ', calories: 320, protein: 16, carbs: 35, fat: 12, reason: 'Thực vật'),
          MealSuggestion(name: 'Cơm chiên nấm', nameEn: 'Mushroom fried rice', description: 'Thơm,healthy', calories: 460, protein: 18, carbs: 60, fat: 16, reason: 'Chất xơ từ nấm'),
        ]);
      }
    } else {
      // Snack - Bữa phụ (cho tất cả mục tiêu)
      allDishes.addAll([
        MealSuggestion(name: 'Sữa chua Hy Lạp', nameEn: 'Greek yogurt', description: 'Giàu protein', calories: 120, protein: 15, carbs: 8, fat: 3, reason: 'Snack protein cao, ít calo'),
        MealSuggestion(name: 'Chuối', nameEn: 'Banana', description: 'Năng lượng nhanh', calories: 100, protein: 1, carbs: 25, fat: 0, reason: 'Bổ sung năng lượng nhanh'),
        MealSuggestion(name: 'Hạt điều (30g)', nameEn: 'Cashew nuts 30g', description: 'Chất béo tốt', calories: 165, protein: 5, carbs: 9, fat: 13, reason: 'Chất béo lành mạnh, no lâu'),
        MealSuggestion(name: 'Trứng luộc (2 quả)', nameEn: 'Boiled eggs x2', description: 'Protein hoàn chỉnh', calories: 140, protein: 12, carbs: 2, fat: 10, reason: 'Protein chất lượng cao'),
        MealSuggestion(name: 'Táo đỏ', nameEn: 'Red apple', description: 'Giàu chất xơ', calories: 80, protein: 0, carbs: 21, fat: 0, reason: 'Ít calo, nhiều vitamin'),
        MealSuggestion(name: 'Sữa hạt óc chó 200ml', nameEn: 'Walnut milk 200ml', description: 'Omega-3 thực vật', calories: 130, protein: 4, carbs: 12, fat: 8, reason: 'Chất béo tốt, nhẹ nhàng'),
        MealSuggestion(name: 'Bánh gạo lứt (3 cái)', nameEn: 'Brown rice cakes x3', description: 'Ít calo, giòn', calories: 110, protein: 2, carbs: 24, fat: 1, reason: 'Snack ít calo duy trì năng lượng'),
        MealSuggestion(name: 'Phô mai que (2 cái)', nameEn: 'String cheese x2', description: 'Canxi và protein', calories: 150, protein: 12, carbs: 2, fat: 10, reason: 'Protein và canxi, no lâu'),
        MealSuggestion(name: 'Cam + ổi', nameEn: 'Orange and guava', description: 'Vitamin C cao', calories: 120, protein: 2, carbs: 28, fat: 0, reason: 'Vitamin C, tăng đề kháng'),
        MealSuggestion(name: 'Chè đậu xanh ít đường', nameEn: 'Light mung bean sweet soup', description: 'Mát lành, giải nhiệt', calories: 160, protein: 6, carbs: 30, fat: 2, reason: 'Protein thực vật nhẹ nhàng'),
        MealSuggestion(name: 'Khoai lang luộc (1 củ)', nameEn: 'Boiled sweet potato', description: 'Chất xơ và beta-carotene', calories: 130, protein: 2, carbs: 30, fat: 0, reason: 'GI thấp, no lâu không béo'),
        MealSuggestion(name: 'Bắp luộc', nameEn: 'Boiled corn', description: 'Tự nhiên – ngọt', calories: 100, protein: 3, carbs: 22, fat: 1, reason: 'Chất xơ cao, ít calo'),
        // NEW: Additional Vietnamese snacks
        MealSuggestion(name: 'Bánh gai', nameEn: 'Black sesame cake', description: 'Truyền thống', calories: 180, protein: 4, carbs: 28, fat: 7, reason: 'Bánh truyền thống Việt Nam'),
        MealSuggestion(name: 'Bánh pía', nameEn: 'Pia cake', description: 'Bánh ngọt Sài Gòn', calories: 200, protein: 5, carbs: 32, fat: 6, reason: 'Đặc sản miền Tây'),
        MealSuggestion(name: 'Mít sấy', nameEn: 'Dried jackfruit', description: 'Giòn ngọt', calories: 140, protein: 2, carbs: 30, fat: 1, reason: 'Vitamin A, C tự nhiên'),
        MealSuggestion(name: 'Khô bò', nameEn: 'Dried beef', description: 'Protein cao', calories: 250, protein: 35, carbs: 5, fat: 10, reason: 'Protein từ thịt bò, no lâu'),
        MealSuggestion(name: 'Nấm khô xào', nameEn: 'Stir-fried dried mushroom', description: 'Chất xơ thực vật', calories: 80, protein: 5, carbs: 12, fat: 2, reason: 'Ít calo, giàu chất xơ'),
        MealSuggestion(name: 'Đậu phộng rang (30g)', nameEn: 'Roasted peanuts 30g', description: 'Giòn thơm', calories: 170, protein: 7, carbs: 6, fat: 14, reason: 'Chất béo tốt, protein thực vật'),
        MealSuggestion(name: 'Chuối sấy', nameEn: 'Dried banana', description: 'Năng lượng tự nhiên', calories: 120, protein: 1, carbs: 28, fat: 1, reason: 'Năng lượng nhanh từ chuối'),
        MealSuggestion(name: 'Sữa đậu nành', nameEn: 'Soy milk', description: 'Thực vật, giàu đạm', calories: 100, protein: 7, carbs: 6, fat: 4, reason: 'Đạm thực vật, ít calo'),
        MealSuggestion(name: 'Trà đá', nameEn: 'Iced tea (unsweetened)', description: 'Giải khát, ít calo', calories: 30, protein: 0, carbs: 7, fat: 0, reason: 'Giải khát, không calo'),
        MealSuggestion(name: 'Bánh rán đường phèn', nameEn: 'Sweet rice ball', description: 'Truyền thống Hà Nội', calories: 190, protein: 4, carbs: 36, fat: 4, reason: 'Món truyền thống, năng lượng vừa'),
      ]);
    }

    // Lọc theo calo target của bữa (±tolerance) hoặc tất cả nếu snack
    List<MealSuggestion> filtered;
    if (mealTime == 'snack') {
      filtered = allDishes.where((s) => s.calories <= 250).toList();
    } else {
      filtered = allDishes.where((s) =>
        s.calories >= (mealTarget - tolerance) &&
        s.calories <= (mealTarget + tolerance)
      ).toList();

      // Nếu không có món nào phù hợp dải hẹp, mở rộng lọc
      if (filtered.isEmpty) {
        filtered = allDishes.where((s) => s.calories <= remainingCalories + 100).toList();
      }
    }

    // Trả tối đa 5 món
    return filtered.take(5).toList();
  }

  /// Tính toán phân bổ calo theo mục tiêu người dùng
  /// Ví dụ: 1m70, 65kg cần 1634 kcal/ngày
  /// - Bữa sáng: 300 kcal → Còn lại 1334 kcal cho trưa, phụ, tối
  /// - Với ±50 kcal tolerance
  static MealCalorieDistribution calculateMealDistribution({
    required double dailyTargetCalories,
    required String goal,
    double breakfastCalories = 300,
  }) {
    double lunchTarget;
    double snackTarget;
    double dinnerTarget;
    
    // Tính remaining sau khi trừ breakfast
    final remainingAfterBreakfast = dailyTargetCalories - breakfastCalories;
    
    if (goal == 'lose') {
      // Giảm cân: Ưu tiên bữa trưa nhiều hơn, tối nhẹ
      // Phân bổ: Trưa 45%, Phụ 15%, Tối 40% của remaining
      lunchTarget = remainingAfterBreakfast * 0.45;
      snackTarget = remainingAfterBreakfast * 0.15;
      dinnerTarget = remainingAfterBreakfast * 0.40;
    } else if (goal == 'gain') {
      // Tăng cân: Ăn nhiều hơn, đặc biệt bữa tối để phục hồi cơ
      // Phân bổ: Trưa 40%, Phụ 15%, Tối 45% của remaining
      lunchTarget = remainingAfterBreakfast * 0.40;
      snackTarget = remainingAfterBreakfast * 0.15;
      dinnerTarget = remainingAfterBreakfast * 0.45;
    } else {
      // Duy trì: Phân bổ đều
      // Phân bổ: Trưa 40%, Phụ 15%, Tối 45% của remaining
      lunchTarget = remainingAfterBreakfast * 0.40;
      snackTarget = remainingAfterBreakfast * 0.15;
      dinnerTarget = remainingAfterBreakfast * 0.45;
    }

    return MealCalorieDistribution(
      breakfast: breakfastCalories.toInt(),
      lunch: lunchTarget.round(),
      snack: snackTarget.round(),
      dinner: dinnerTarget.round(),
      tolerance: 50,
    );
  }

  /// Lấy thông tin phân bổ calo cho bữa ăn hiện tại
  static MealCalorieDistribution? getCurrentMealDistribution(UserProfile profile) {
    final hour = DateTime.now().hour;
    final distribution = calculateMealDistribution(
      dailyTargetCalories: profile.dailyTarget,
      goal: profile.goal,
    );

    if (hour < 10) {
      return distribution.copyWith(
        currentMealTarget: distribution.breakfast,
        mealName: 'breakfast',
      );
    } else if (hour < 14) {
      return distribution.copyWith(
        currentMealTarget: distribution.lunch,
        mealName: 'lunch',
      );
    } else if (hour < 17) {
      return distribution.copyWith(
        currentMealTarget: distribution.snack,
        mealName: 'snack',
      );
    } else {
      return distribution.copyWith(
        currentMealTarget: distribution.dinner,
        mealName: 'dinner',
      );
    }
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

/// Phân bổ calo cho các bữa ăn trong ngày
/// Ví dụ: 1m70, 65kg cần 1634 kcal/ngày
/// - Bữa sáng: 300 kcal
/// - Bữa trưa: ~534 kcal (1334 * 0.40)
/// - Bữa phụ: ~200 kcal (1334 * 0.15)  
/// - Bữa tối: ~600 kcal (1334 * 0.45)
/// Với tolerance ±50 kcal
class MealCalorieDistribution {
  final int breakfast;
  final int lunch;
  final int snack;
  final int dinner;
  final int tolerance;
  final int? currentMealTarget;
  final String? mealName;

  MealCalorieDistribution({
    required this.breakfast,
    required this.lunch,
    required this.snack,
    required this.dinner,
    this.tolerance = 50,
    this.currentMealTarget,
    this.mealName,
  });

  MealCalorieDistribution copyWith({
    int? breakfast,
    int? lunch,
    int? snack,
    int? dinner,
    int? tolerance,
    int? currentMealTarget,
    String? mealName,
  }) {
    return MealCalorieDistribution(
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      snack: snack ?? this.snack,
      dinner: dinner ?? this.dinner,
      tolerance: tolerance ?? this.tolerance,
      currentMealTarget: currentMealTarget ?? this.currentMealTarget,
      mealName: mealName ?? this.mealName,
    );
  }

  /// Lấy khoảng calo cho bữa ăn cụ thể (với tolerance)
  (int min, int max) getMealRange(String meal) {
    switch (meal) {
      case 'breakfast':
        return (breakfast - tolerance, breakfast + tolerance);
      case 'lunch':
        return (lunch - tolerance, lunch + tolerance);
      case 'snack':
        return (snack - tolerance, snack + tolerance);
      case 'dinner':
        return (dinner - tolerance, dinner + tolerance);
      default:
        return (0, 9999);
    }
  }

  /// Tổng calo của tất cả các bữa
  int get totalCalories => breakfast + lunch + snack + dinner;

  @override
  String toString() {
    return 'MealCalorieDistribution(sáng: $breakfast±$tolerance, trưa: $lunch±$tolerance, phụ: $snack±$tolerance, tối: $dinner±$tolerance)';
  }
}
