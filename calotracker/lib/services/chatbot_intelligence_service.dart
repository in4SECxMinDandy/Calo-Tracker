// ============================================================
// ChatbotIntelligenceService - AI Chatbot nội bộ
// Xử lý câu hỏi dinh dưỡng hoàn toàn offline
// Không phụ thuộc API bên ngoài
// ============================================================

import '../data/food_database.dart';
import '../models/meal.dart';
import '../services/database_service.dart';

/// Loại intent của câu hỏi người dùng
enum ChatIntent {
  /// Hỏi thông tin dinh dưỡng của món ăn
  nutritionQuery,

  /// Hỏi gợi ý món ăn lành mạnh
  healthyAlternative,

  /// Phân tích thói quen ăn uống
  habitAnalysis,

  /// Thêm bữa ăn vào nhật ký
  addMeal,

  /// Hỏi về mục tiêu calo
  calorieGoal,

  /// Câu hỏi chung về dinh dưỡng
  generalNutrition,

  /// Không nhận diện được
  unknown,
}

/// Kết quả phân tích câu hỏi
class ChatAnalysis {
  final ChatIntent intent;
  final String? foodName;
  final double? weightGrams;
  final String rawQuery;

  const ChatAnalysis({
    required this.intent,
    required this.rawQuery,
    this.foodName,
    this.weightGrams,
  });
}

/// Phản hồi từ chatbot
class ChatbotResponse {
  /// Nội dung tin nhắn văn bản
  final String message;

  /// Dữ liệu dinh dưỡng (nếu có)
  final FoodNutritionAnalysis? nutritionData;

  /// Danh sách gợi ý thay thế (nếu có)
  final List<FoodItem> alternatives;

  /// Có thể thêm vào nhật ký không
  final bool canAddToLog;

  /// Thông tin bữa ăn để thêm vào nhật ký
  final Meal? mealToAdd;

  const ChatbotResponse({
    required this.message,
    this.nutritionData,
    this.alternatives = const [],
    this.canAddToLog = false,
    this.mealToAdd,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
/// [ChatbotIntelligenceService] — Xử lý logic AI chatbot nội bộ
///
/// Phân tích câu hỏi người dùng và trả lời dựa trên [FoodDatabaseService].
/// Hoạt động hoàn toàn offline, không cần kết nối internet.
///
/// Cách dùng:
/// ```dart
/// final response = await ChatbotIntelligenceService.processMessage(
///   '200g phở bò',
///   userId: 'user123',
/// );
/// print(response.message);
/// ```
// ─────────────────────────────────────────────────────────────────────────────
class ChatbotIntelligenceService {
  ChatbotIntelligenceService._();

  // ── Từ khóa nhận diện intent ───────────────────────────────────────────────
  static const _healthKeywords = [
    'lành mạnh', 'healthy', 'thay thế', 'alternative', 'tốt hơn',
    'ít calo', 'ít béo', 'giảm cân', 'diet', 'ăn kiêng',
  ];

  static const _habitKeywords = [
    'thói quen', 'habit', 'phân tích', 'analyze', 'lịch sử',
    'history', 'hôm nay', 'tuần này', 'tháng này', 'tổng kết',
  ];

  static const _addMealKeywords = [
    'thêm', 'add', 'ghi', 'log', 'nhật ký', 'diary',
    'đã ăn', 'vừa ăn', 'ăn rồi',
  ];

  static const _calorieKeywords = [
    'calo', 'calorie', 'mục tiêu', 'goal', 'còn lại', 'remaining',
    'đã nạp', 'consumed', 'hôm nay ăn',
  ];

  static const _generalNutritionKeywords = [
    'protein', 'carb', 'fat', 'chất béo', 'đường', 'chất xơ',
    'fiber', 'vitamin', 'khoáng chất', 'mineral', 'dinh dưỡng',
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Xử lý tin nhắn từ người dùng và trả về phản hồi
  ///
  /// [message] — tin nhắn của người dùng
  /// [userId] — ID người dùng (để truy vấn lịch sử ăn uống)
  static Future<ChatbotResponse> processMessage(
    String message, {
    String? userId,
  }) async {
    final analysis = _analyzeIntent(message);

    switch (analysis.intent) {
      case ChatIntent.nutritionQuery:
        return _handleNutritionQuery(analysis);

      case ChatIntent.healthyAlternative:
        return _handleHealthyAlternative(analysis);

      case ChatIntent.habitAnalysis:
        return await _handleHabitAnalysis(userId);

      case ChatIntent.addMeal:
        return _handleAddMeal(analysis);

      case ChatIntent.calorieGoal:
        return await _handleCalorieGoal(userId);

      case ChatIntent.generalNutrition:
        return _handleGeneralNutrition(analysis);

      case ChatIntent.unknown:
        return _handleUnknown(message);
    }
  }

  // ── Intent Analysis ────────────────────────────────────────────────────────

  /// Phân tích intent từ tin nhắn người dùng
  static ChatAnalysis _analyzeIntent(String message) {
    final lower = message.toLowerCase().trim();

    // Kiểm tra intent thêm bữa ăn
    if (_containsAny(lower, _addMealKeywords)) {
      final parsed = _parseFoodAndWeight(message);
      return ChatAnalysis(
        intent: ChatIntent.addMeal,
        rawQuery: message,
        foodName: parsed.$1,
        weightGrams: parsed.$2,
      );
    }

    // Kiểm tra intent phân tích thói quen
    if (_containsAny(lower, _habitKeywords)) {
      return ChatAnalysis(intent: ChatIntent.habitAnalysis, rawQuery: message);
    }

    // Kiểm tra intent calo mục tiêu
    if (_containsAny(lower, _calorieKeywords)) {
      return ChatAnalysis(intent: ChatIntent.calorieGoal, rawQuery: message);
    }

    // Kiểm tra intent gợi ý lành mạnh
    if (_containsAny(lower, _healthKeywords)) {
      final parsed = _parseFoodAndWeight(message);
      return ChatAnalysis(
        intent: ChatIntent.healthyAlternative,
        rawQuery: message,
        foodName: parsed.$1,
        weightGrams: parsed.$2,
      );
    }

    // Kiểm tra intent dinh dưỡng chung
    if (_containsAny(lower, _generalNutritionKeywords)) {
      final parsed = _parseFoodAndWeight(message);
      return ChatAnalysis(
        intent: ChatIntent.generalNutrition,
        rawQuery: message,
        foodName: parsed.$1,
        weightGrams: parsed.$2,
      );
    }

    // Mặc định: tìm kiếm thông tin dinh dưỡng
    final parsed = _parseFoodAndWeight(message);
    if (parsed.$1 != null) {
      return ChatAnalysis(
        intent: ChatIntent.nutritionQuery,
        rawQuery: message,
        foodName: parsed.$1,
        weightGrams: parsed.$2,
      );
    }

    return ChatAnalysis(intent: ChatIntent.unknown, rawQuery: message);
  }

  // ── Intent Handlers ────────────────────────────────────────────────────────

  /// Xử lý câu hỏi thông tin dinh dưỡng
  static ChatbotResponse _handleNutritionQuery(ChatAnalysis analysis) {
    if (analysis.foodName == null) {
      return const ChatbotResponse(
        message: 'Bạn muốn biết thông tin dinh dưỡng của món gì? '
            'Ví dụ: "phở bò", "200g cơm trắng", "1 quả chuối"',
      );
    }

    final nutrition = FoodDatabaseService.analyze(
      analysis.foodName!,
      weightGrams: analysis.weightGrams,
    );

    if (nutrition == null) {
      // Thử tìm kiếm gần đúng
      final results = FoodDatabaseService.search(analysis.foodName!);
      if (results.isNotEmpty) {
        final suggestions = results.take(3).map((r) => r.food.name).join(', ');
        return ChatbotResponse(
          message: '❓ Không tìm thấy "${analysis.foodName}" trong cơ sở dữ liệu.\n\n'
              'Bạn có muốn tìm kiếm: **$suggestions**?',
        );
      }
      return ChatbotResponse(
        message: '❓ Không tìm thấy thông tin về "${analysis.foodName}".\n\n'
            'Thử nhập tên khác hoặc kiểm tra chính tả.',
      );
    }

    final food = nutrition.food;
    final weight = nutrition.weightGrams;
    final weightStr = weight == food.servingSize
        ? '${weight.toStringAsFixed(0)}g (1 ${food.servingUnit})'
        : '${weight.toStringAsFixed(0)}g';

    final alternatives = FoodDatabaseService.getHealthierAlternatives(food);
    final altText = alternatives.isNotEmpty
        ? '\n\n💡 **Thay thế lành mạnh hơn:** ${alternatives.map((a) => a.name).join(', ')}'
        : '';

    final healthEmoji = _getHealthEmoji(food.healthScore);

    return ChatbotResponse(
      message: '$healthEmoji **${food.name}** ($weightStr)\n\n'
          '🔥 Calo: **${nutrition.calories.toStringAsFixed(0)} kcal**\n'
          '💪 Protein: ${nutrition.protein.toStringAsFixed(1)}g\n'
          '🌾 Carbs: ${nutrition.carbs.toStringAsFixed(1)}g\n'
          '🥑 Fat: ${nutrition.fat.toStringAsFixed(1)}g\n'
          '🌿 Chất xơ: ${nutrition.fiber.toStringAsFixed(1)}g\n\n'
          '📝 ${food.nutritionNote}'
          '$altText',
      nutritionData: nutrition,
      alternatives: alternatives,
      canAddToLog: true,
      mealToAdd: _createMealFromNutrition(nutrition),
    );
  }

  /// Xử lý câu hỏi gợi ý thay thế lành mạnh
  static ChatbotResponse _handleHealthyAlternative(ChatAnalysis analysis) {
    if (analysis.foodName == null) {
      // Gợi ý danh sách món lành mạnh
      final healthyFoods = FoodDatabaseService.getHealthyFoods().take(6).toList();
      final foodList = healthyFoods
          .map((f) => '${_getHealthEmoji(f.healthScore)} ${f.name} '
              '(${f.servingCalories.toStringAsFixed(0)} kcal/${f.servingUnit})')
          .join('\n');

      return ChatbotResponse(
        message: '🥗 **Các món ăn lành mạnh được gợi ý:**\n\n$foodList\n\n'
            'Hỏi tôi về bất kỳ món nào để biết thêm chi tiết!',
        alternatives: healthyFoods,
      );
    }

    final food = FoodDatabaseService.findBest(analysis.foodName!);
    if (food == null) {
      return ChatbotResponse(
        message: '❓ Không tìm thấy "${analysis.foodName}". '
            'Thử nhập tên khác.',
      );
    }

    final alternatives = FoodDatabaseService.getHealthierAlternatives(food);
    if (alternatives.isEmpty) {
      return ChatbotResponse(
        message: '✅ **${food.name}** đã là lựa chọn lành mạnh '
            '(điểm sức khỏe: ${food.healthScore}/5)!\n\n'
            '${food.nutritionNote}',
      );
    }

    final altDetails = alternatives.map((alt) {
      final diff = alt.servingCalories - food.servingCalories;
      final diffStr = diff < 0
          ? '(-${(-diff).toStringAsFixed(0)} kcal)'
          : '(+${diff.toStringAsFixed(0)} kcal)';
      return '${_getHealthEmoji(alt.healthScore)} **${alt.name}** '
          '${alt.servingCalories.toStringAsFixed(0)} kcal $diffStr';
    }).join('\n');

    return ChatbotResponse(
      message: '💡 **Thay thế lành mạnh hơn cho ${food.name}:**\n\n'
          '$altDetails\n\n'
          '📊 ${food.name} hiện tại: ${food.servingCalories.toStringAsFixed(0)} kcal/${food.servingUnit}',
      alternatives: alternatives,
    );
  }

  /// Xử lý phân tích thói quen ăn uống
  static Future<ChatbotResponse> _handleHabitAnalysis(String? userId) async {
    try {
      // Lấy dữ liệu bữa ăn hôm nay
      final todayRecord = await DatabaseService.getTodayRecord();
      final allMeals = await DatabaseService.getAllMeals();

      // Lọc bữa ăn trong 7 ngày qua
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final recentMeals = allMeals.where((m) => m.dateTime.isAfter(weekAgo)).toList();

      if (recentMeals.isEmpty) {
        return const ChatbotResponse(
          message: '📊 Chưa có đủ dữ liệu để phân tích.\n\n'
              'Hãy ghi lại bữa ăn hàng ngày để tôi có thể phân tích thói quen ăn uống của bạn!',
        );
      }

      // Tính toán thống kê
      final totalCalories = recentMeals.fold<double>(0, (sum, m) => sum + m.calories);
      final avgDailyCalories = totalCalories / 7;
      final totalMeals = recentMeals.length;
      final avgMealsPerDay = totalMeals / 7;

      // Tính tổng protein, carbs, fat
      final totalProtein = recentMeals.fold<double>(0, (sum, m) => sum + (m.protein ?? 0));
      final totalCarbs = recentMeals.fold<double>(0, (sum, m) => sum + (m.carbs ?? 0));
      final totalFat = recentMeals.fold<double>(0, (sum, m) => sum + (m.fat ?? 0));

      // Hôm nay
      final todayCalories = todayRecord.caloIntake;
      final todayBurned = todayRecord.caloBurned;

      // Nhận xét
      final comments = <String>[];
      if (avgDailyCalories < 1200) {
        comments.add('⚠️ Lượng calo trung bình thấp. Hãy đảm bảo ăn đủ dinh dưỡng.');
      } else if (avgDailyCalories > 2500) {
        comments.add('⚠️ Lượng calo trung bình cao. Cân nhắc giảm khẩu phần.');
      } else {
        comments.add('✅ Lượng calo trong mức hợp lý.');
      }

      if (avgMealsPerDay < 2) {
        comments.add('⚠️ Số bữa ăn ít. Nên ăn 3-5 bữa nhỏ mỗi ngày.');
      } else if (avgMealsPerDay >= 3) {
        comments.add('✅ Số bữa ăn đều đặn.');
      }

      final commentText = comments.join('\n');

      return ChatbotResponse(
        message: '📊 **Phân tích thói quen ăn uống (7 ngày qua)**\n\n'
            '🔥 TB calo/ngày: **${avgDailyCalories.toStringAsFixed(0)} kcal**\n'
            '🍽️ TB bữa/ngày: **${avgMealsPerDay.toStringAsFixed(1)} bữa**\n'
            '💪 Tổng protein: ${totalProtein.toStringAsFixed(0)}g\n'
            '🌾 Tổng carbs: ${totalCarbs.toStringAsFixed(0)}g\n'
            '🥑 Tổng fat: ${totalFat.toStringAsFixed(0)}g\n\n'
            '📅 **Hôm nay:**\n'
            '  Nạp vào: ${todayCalories.toStringAsFixed(0)} kcal\n'
            '  Đốt cháy: ${todayBurned.toStringAsFixed(0)} kcal\n'
            '  Thực tế: ${(todayCalories - todayBurned).toStringAsFixed(0)} kcal\n\n'
            '💡 **Nhận xét:**\n$commentText',
      );
    } catch (e) {
      return const ChatbotResponse(
        message: '❌ Không thể tải dữ liệu. Vui lòng thử lại.',
      );
    }
  }

  /// Xử lý câu hỏi về calo mục tiêu
  static Future<ChatbotResponse> _handleCalorieGoal(String? userId) async {
    try {
      final todayRecord = await DatabaseService.getTodayRecord();
      final intake = todayRecord.caloIntake;
      final burned = todayRecord.caloBurned;
      final net = intake - burned;

      // Lấy mục tiêu từ profile
      final profile = await DatabaseService.getUser();
      final target = profile?.dailyTarget ?? 2000;
      final remaining = target - intake;

      final statusEmoji = remaining > 0 ? '✅' : '⚠️';
      final remainingText = remaining > 0
          ? 'Còn có thể nạp: **${remaining.toStringAsFixed(0)} kcal**'
          : 'Đã vượt mục tiêu: **${(-remaining).toStringAsFixed(0)} kcal**';

      return ChatbotResponse(
        message: '🎯 **Tình trạng calo hôm nay**\n\n'
            '📊 Mục tiêu: **${target.toStringAsFixed(0)} kcal**\n'
            '🍽️ Đã nạp: **${intake.toStringAsFixed(0)} kcal**\n'
            '🏃 Đã đốt: **${burned.toStringAsFixed(0)} kcal**\n'
            '⚖️ Thực tế (net): **${net.toStringAsFixed(0)} kcal**\n\n'
            '$statusEmoji $remainingText\n\n'
            '💡 Tiến độ: ${((intake / target) * 100).toStringAsFixed(0)}%',
      );
    } catch (e) {
      return const ChatbotResponse(
        message: '❌ Không thể tải dữ liệu calo. Vui lòng thử lại.',
      );
    }
  }

  /// Xử lý câu hỏi dinh dưỡng chung
  static ChatbotResponse _handleGeneralNutrition(ChatAnalysis analysis) {
    final lower = analysis.rawQuery.toLowerCase();

    if (lower.contains('protein')) {
      return const ChatbotResponse(
        message: '💪 **Protein (Đạm)**\n\n'
            '• Cần thiết cho xây dựng và phục hồi cơ bắp\n'
            '• Nhu cầu: 0.8-2g/kg cân nặng/ngày\n'
            '• Nguồn tốt: thịt gà, cá, trứng, đậu phụ, đậu lăng\n\n'
            '🏆 **Top protein cao:**\n'
            '• Tôm hấp: 24g/100g\n'
            '• Gà luộc: 31g/100g\n'
            '• Cá hồi: 20g/100g\n'
            '• Trứng luộc: 13g/100g',
      );
    }

    if (lower.contains('carb') || lower.contains('tinh bột')) {
      return const ChatbotResponse(
        message: '🌾 **Carbohydrate (Tinh bột)**\n\n'
            '• Nguồn năng lượng chính của cơ thể\n'
            '• Nên chiếm 45-65% tổng calo\n'
            '• Ưu tiên carb phức tạp: gạo lứt, yến mạch, khoai lang\n'
            '• Hạn chế carb đơn giản: đường, bánh kẹo\n\n'
            '✅ **Carb lành mạnh:**\n'
            '• Gạo lứt: 25.6g/100g, nhiều chất xơ\n'
            '• Yến mạch: 12g/100g (nấu), giàu beta-glucan\n'
            '• Khoai lang: 20.1g/100g, giàu vitamin A',
      );
    }

    if (lower.contains('fat') || lower.contains('chất béo')) {
      return const ChatbotResponse(
        message: '🥑 **Chất béo (Fat)**\n\n'
            '• Cần thiết cho hấp thụ vitamin và hormone\n'
            '• Nên chiếm 20-35% tổng calo\n'
            '• Ưu tiên chất béo không bão hòa\n\n'
            '✅ **Chất béo lành mạnh:**\n'
            '• Bơ (avocado): omega-9, kali\n'
            '• Cá hồi: omega-3 DHA/EPA\n'
            '• Hạt hỗn hợp: omega-3, vitamin E\n\n'
            '❌ **Hạn chế:**\n'
            '• Chất béo bão hòa (thịt đỏ nhiều mỡ)\n'
            '• Chất béo trans (đồ chiên rán)',
      );
    }

    if (lower.contains('chất xơ') || lower.contains('fiber')) {
      return const ChatbotResponse(
        message: '🌿 **Chất xơ (Fiber)**\n\n'
            '• Tốt cho tiêu hóa và kiểm soát đường huyết\n'
            '• Nhu cầu: 25-38g/ngày\n\n'
            '✅ **Nguồn chất xơ cao:**\n'
            '• Bơ (avocado): 6.7g/100g\n'
            '• Hạt hỗn hợp: 7g/100g\n'
            '• Khoai lang: 3g/100g\n'
            '• Rau muống: 2.1g/100g\n'
            '• Táo: 2.4g/100g',
      );
    }

    // Nếu có tên món ăn, trả về thông tin dinh dưỡng
    if (analysis.foodName != null) {
      return _handleNutritionQuery(analysis);
    }

    return const ChatbotResponse(
      message: '🥗 **Nguyên tắc dinh dưỡng cơ bản:**\n\n'
          '1. **Cân bằng macro:** 30% protein, 40% carbs, 30% fat\n'
          '2. **Ăn đủ rau xanh:** ít nhất 400g/ngày\n'
          '3. **Uống đủ nước:** 2-3 lít/ngày\n'
          '4. **Ăn đúng giờ:** 3-5 bữa nhỏ/ngày\n'
          '5. **Hạn chế đường và muối**\n\n'
          'Hỏi tôi về bất kỳ món ăn nào để biết thông tin dinh dưỡng!',
    );
  }

  /// Xử lý câu hỏi thêm bữa ăn
  static ChatbotResponse _handleAddMeal(ChatAnalysis analysis) {
    if (analysis.foodName == null) {
      return const ChatbotResponse(
        message: '🍽️ Bạn muốn thêm món gì vào nhật ký?\n\n'
            'Ví dụ: "thêm 200g phở bò" hoặc "đã ăn 1 tô bún chả"',
      );
    }

    final nutrition = FoodDatabaseService.analyze(
      analysis.foodName!,
      weightGrams: analysis.weightGrams,
    );

    if (nutrition == null) {
      return ChatbotResponse(
        message: '❓ Không tìm thấy "${analysis.foodName}".\n\n'
            'Thử nhập tên khác hoặc kiểm tra chính tả.',
      );
    }

    return ChatbotResponse(
      message: '✅ **Thêm vào nhật ký:**\n\n'
          '🍽️ ${nutrition.food.name} (${nutrition.weightGrams.toStringAsFixed(0)}g)\n'
          '🔥 ${nutrition.calories.toStringAsFixed(0)} kcal\n'
          '💪 Protein: ${nutrition.protein.toStringAsFixed(1)}g\n'
          '🌾 Carbs: ${nutrition.carbs.toStringAsFixed(1)}g\n'
          '🥑 Fat: ${nutrition.fat.toStringAsFixed(1)}g\n\n'
          'Nhấn nút bên dưới để thêm vào nhật ký.',
      nutritionData: nutrition,
      canAddToLog: true,
      mealToAdd: _createMealFromNutrition(nutrition),
    );
  }

  /// Xử lý câu hỏi không nhận diện được
  static ChatbotResponse _handleUnknown(String message) {
    // Thử tìm kiếm trong database
    final results = FoodDatabaseService.search(message, maxResults: 3);

    if (results.isNotEmpty) {
      final suggestions = results
          .map((r) => '• **${r.food.name}**: ${r.food.servingCalories.toStringAsFixed(0)} kcal/${r.food.servingUnit}')
          .join('\n');

      return ChatbotResponse(
        message: '🔍 Tôi tìm thấy một số kết quả liên quan:\n\n'
            '$suggestions\n\n'
            'Nhập tên món ăn cụ thể hơn để biết thông tin chi tiết!',
      );
    }

    return const ChatbotResponse(
      message: '🤔 Tôi chưa hiểu câu hỏi của bạn.\n\n'
          '**Tôi có thể giúp bạn:**\n'
          '• 🔍 Tra cứu dinh dưỡng: "phở bò", "200g cơm trắng"\n'
          '• 💡 Gợi ý lành mạnh: "thay thế cho burger"\n'
          '• 📊 Phân tích thói quen: "phân tích thói quen ăn uống"\n'
          '• 🎯 Kiểm tra calo: "hôm nay ăn bao nhiêu calo"\n'
          '• ➕ Thêm bữa ăn: "thêm 1 tô phở bò"\n\n'
          'Hãy thử lại!',
    );
  }

  // ── Helper Methods ─────────────────────────────────────────────────────────

  /// Phân tích tên món ăn và khối lượng từ câu hỏi
  ///
  /// Ví dụ: "200g phở bò" → ('phở bò', 200.0)
  /// Ví dụ: "1 tô bún chả" → ('bún chả', null)
  static (String?, double?) _parseFoodAndWeight(String message) {
    final lower = message.toLowerCase().trim();

    // Pattern: số + đơn vị + tên món
    // Ví dụ: "200g phở bò", "100 gram cơm", "2 tô bún"
    final weightPattern = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:g|gram|gam|kg|tô|bát|chén|phần|cái|quả|ly|hộp)?\s+(.+)',
    );
    final match = weightPattern.firstMatch(lower);

    if (match != null) {
      final weightStr = match.group(1);
      final foodName = match.group(2)?.trim();
      final weight = weightStr != null ? double.tryParse(weightStr) : null;

      // Loại bỏ các từ khóa không phải tên món
      final cleanedFoodName = _cleanFoodName(foodName ?? '');
      return (cleanedFoodName.isNotEmpty ? cleanedFoodName : null, weight);
    }

    // Không có số lượng, lấy toàn bộ làm tên món
    final cleanedName = _cleanFoodName(lower);
    return (cleanedName.isNotEmpty ? cleanedName : null, null);
  }

  /// Làm sạch tên món ăn (loại bỏ từ khóa không liên quan)
  static String _cleanFoodName(String name) {
    const stopWords = [
      'thêm', 'add', 'ghi', 'log', 'nhật ký', 'diary',
      'đã ăn', 'vừa ăn', 'ăn rồi', 'cho tôi biết', 'thông tin',
      'dinh dưỡng', 'calo', 'calorie', 'của', 'về', 'là',
      'thay thế', 'lành mạnh', 'healthy', 'alternative',
      'phân tích', 'thói quen', 'hôm nay', 'tuần này',
    ];

    var cleaned = name.trim();
    for (final word in stopWords) {
      cleaned = cleaned.replaceAll(word, '').trim();
    }

    // Loại bỏ khoảng trắng thừa
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  /// Kiểm tra chuỗi có chứa bất kỳ từ khóa nào không
  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Lấy emoji theo điểm sức khỏe
  static String _getHealthEmoji(int healthScore) {
    switch (healthScore) {
      case 5:
        return '🥗';
      case 4:
        return '✅';
      case 3:
        return '🍽️';
      case 2:
        return '⚠️';
      case 1:
        return '❌';
      default:
        return '🍽️';
    }
  }

  /// Tạo đối tượng Meal từ phân tích dinh dưỡng
  static Meal _createMealFromNutrition(FoodNutritionAnalysis nutrition) {
    return Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dateTime: DateTime.now(),
      foodName: nutrition.food.name,
      weight: nutrition.weightGrams,
      calories: nutrition.calories,
      protein: nutrition.protein,
      carbs: nutrition.carbs,
      fat: nutrition.fat,
      source: 'chatbot',
    );
  }
}
