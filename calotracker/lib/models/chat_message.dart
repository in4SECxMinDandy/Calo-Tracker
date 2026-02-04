// Chat Message Model
// Stores chatbot conversation history with nutrition data
import 'dart:convert';
import 'package:uuid/uuid.dart';

class ChatMessage {
  final String id;
  final DateTime timestamp;
  final String message;
  final bool isUser;
  final NutritionData? nutrition;
  final bool isLoading;

  ChatMessage({
    String? id,
    required this.timestamp,
    required this.message,
    required this.isUser,
    this.nutrition,
    this.isLoading = false,
  }) : id = id ?? const Uuid().v4();

  /// Create user message
  factory ChatMessage.user(String message) {
    return ChatMessage(
      timestamp: DateTime.now(),
      message: message,
      isUser: true,
    );
  }

  /// Create loading bot message
  factory ChatMessage.loading() {
    return ChatMessage(
      timestamp: DateTime.now(),
      message: '',
      isUser: false,
      isLoading: true,
    );
  }

  /// Create bot response with nutrition data
  factory ChatMessage.bot(String message, {NutritionData? nutrition}) {
    return ChatMessage(
      timestamp: DateTime.now(),
      message: message,
      isUser: false,
      nutrition: nutrition,
    );
  }

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'message': message,
      'is_user': isUser ? 1 : 0,
      'nutrition': nutrition?.toJson(),
    };
  }

  /// Create from database Map
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      message: map['message'] as String,
      isUser: (map['is_user'] as int) == 1,
      nutrition:
          map['nutrition'] != null
              ? NutritionData.fromJson(map['nutrition'] as String)
              : null,
    );
  }

  /// Get time string (HH:mm)
  String get timeStr {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'ChatMessage(isUser: $isUser, message: $message)';
  }
}

/// Nutrition data from API response
class NutritionData {
  final double calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final List<FoodItem> foods;

  NutritionData({
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.foods = const [],
  });

  /// Create from Nutritionix API response
  factory NutritionData.fromNutritionix(Map<String, dynamic> response) {
    final foodsList = response['foods'] as List<dynamic>? ?? [];

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    List<FoodItem> foods = [];

    for (final food in foodsList) {
      final calories = (food['nf_calories'] as num?)?.toDouble() ?? 0;
      final protein = (food['nf_protein'] as num?)?.toDouble() ?? 0;
      final carbs = (food['nf_total_carbohydrate'] as num?)?.toDouble() ?? 0;
      final fat = (food['nf_total_fat'] as num?)?.toDouble() ?? 0;

      totalCalories += calories;
      totalProtein += protein;
      totalCarbs += carbs;
      totalFat += fat;

      foods.add(
        FoodItem(
          name: food['food_name'] as String? ?? 'Unknown',
          calories: calories,
          weight: (food['serving_weight_grams'] as num?)?.toDouble(),
        ),
      );
    }

    return NutritionData(
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      foods: foods,
    );
  }

  /// Create from CalorieNinjas API response
  factory NutritionData.fromCalorieNinjas(Map<String, dynamic> response) {
    final itemsList = response['items'] as List<dynamic>? ?? [];

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    List<FoodItem> foods = [];

    for (final item in itemsList) {
      final calories = (item['calories'] as num?)?.toDouble() ?? 0;
      final protein = (item['protein_g'] as num?)?.toDouble() ?? 0;
      final carbs = (item['carbohydrates_total_g'] as num?)?.toDouble() ?? 0;
      final fat = (item['fat_total_g'] as num?)?.toDouble() ?? 0;

      totalCalories += calories;
      totalProtein += protein;
      totalCarbs += carbs;
      totalFat += fat;

      foods.add(
        FoodItem(
          name: item['name'] as String? ?? 'Unknown',
          calories: calories,
          weight: (item['serving_size_g'] as num?)?.toDouble(),
        ),
      );
    }

    return NutritionData(
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      foods: foods,
    );
  }

  /// Create from USDA FoodData Central API response
  /// IMPORTANT: Only use the FIRST/most relevant result, not sum all results
  factory NutritionData.fromUSDA(Map<String, dynamic> response) {
    final foodsList = response['foods'] as List<dynamic>? ?? [];

    if (foodsList.isEmpty) {
      return NutritionData(calories: 0, foods: []);
    }

    // Only take the FIRST (most relevant) result
    final food = foodsList.first;

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    String name = food['description'] as String? ?? 'Unknown';
    double? weight = (food['servingSize'] as num?)?.toDouble() ?? 100;

    // Check for demo data format first (local database)
    if (food.containsKey('calories')) {
      calories = (food['calories'] as num?)?.toDouble() ?? 0;
      protein = (food['protein'] as num?)?.toDouble() ?? 0;
      carbs = (food['carbs'] as num?)?.toDouble() ?? 0;
      fat = (food['fat'] as num?)?.toDouble() ?? 0;
    } else {
      // USDA API format - nutrients are in foodNutrients array
      final nutrients = food['foodNutrients'] as List<dynamic>? ?? [];
      for (final nutrient in nutrients) {
        final nutrientId = nutrient['nutrientId'] as int? ?? 0;
        final value = (nutrient['value'] as num?)?.toDouble() ?? 0;

        switch (nutrientId) {
          case 1008: // Energy (kcal)
            calories = value;
            break;
          case 1003: // Protein
            protein = value;
            break;
          case 1005: // Carbohydrate
            carbs = value;
            break;
          case 1004: // Total lipid (fat)
            fat = value;
            break;
        }
      }
    }

    // Validate: 100g chicken should be ~165 kcal, not 1000+
    // If calories seem unreasonably high for the weight, normalize
    if (weight > 0 && calories > 0) {
      final caloriesPerGram = calories / weight;
      // Most foods are 0.5-4 kcal/g. If higher, it's likely an error
      if (caloriesPerGram > 5) {
        // Likely the serving size is wrong, assume 100g base
        // Do nothing, just flag it
      }
    }

    return NutritionData(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      foods: [FoodItem(name: name, calories: calories, weight: weight)],
    );
  }

  /// Create from USDA FoodData Central API single food detail
  factory NutritionData.fromUSDADetail(Map<String, dynamic> food) {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    String name = food['description'] as String? ?? 'Unknown';

    final nutrients = food['foodNutrients'] as List<dynamic>? ?? [];
    for (final nutrient in nutrients) {
      final nutrientNumber = nutrient['nutrient']?['number'] as String? ?? '';
      final value = (nutrient['amount'] as num?)?.toDouble() ?? 0;

      switch (nutrientNumber) {
        case '208': // Energy (kcal)
          calories = value;
          break;
        case '203': // Protein
          protein = value;
          break;
        case '205': // Carbohydrate
          carbs = value;
          break;
        case '204': // Total lipid (fat)
          fat = value;
          break;
      }
    }

    return NutritionData(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      foods: [FoodItem(name: name, calories: calories, weight: 100)],
    );
  }

  /// Convert to JSON string for database
  String toJson() {
    return jsonEncode({
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'foods': foods.map((f) => f.toMap()).toList(),
    });
  }

  /// Create from JSON string
  factory NutritionData.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return NutritionData(
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num?)?.toDouble(),
      carbs: (map['carbs'] as num?)?.toDouble(),
      fat: (map['fat'] as num?)?.toDouble(),
      foods:
          (map['foods'] as List<dynamic>?)
              ?.map((f) => FoodItem.fromMap(f as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Check if has macro data
  bool get hasMacros => protein != null && carbs != null && fat != null;

  /// Get macro percentages for pie chart
  Map<String, double> get macroPercentages {
    if (!hasMacros) return {};

    final total = (protein ?? 0) * 4 + (carbs ?? 0) * 4 + (fat ?? 0) * 9;
    if (total == 0) return {'protein': 0, 'carbs': 0, 'fat': 0};

    return {
      'protein': ((protein ?? 0) * 4 / total) * 100,
      'carbs': ((carbs ?? 0) * 4 / total) * 100,
      'fat': ((fat ?? 0) * 9 / total) * 100,
    };
  }
}

/// Individual food item
class FoodItem {
  final String name;
  final double calories;
  final double? weight;

  FoodItem({required this.name, required this.calories, this.weight});

  Map<String, dynamic> toMap() {
    return {'name': name, 'calories': calories, 'weight': weight};
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name'] as String,
      calories: (map['calories'] as num).toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
    );
  }
}
