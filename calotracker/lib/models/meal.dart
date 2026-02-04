// Meal Model
// Stores individual food entries with nutritional information
import 'package:uuid/uuid.dart';

class Meal {
  final String id;
  final DateTime dateTime;
  final String foodName;
  final double? weight; // grams
  final double calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String source; // 'camera' | 'chatbot' | 'manual'

  Meal({
    String? id,
    required this.dateTime,
    required this.foodName,
    this.weight,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    required this.source,
  }) : id = id ?? const Uuid().v4();

  /// Create from Nutritionix API response food item
  factory Meal.fromNutritionix(Map<String, dynamic> food, String source) {
    return Meal(
      dateTime: DateTime.now(),
      foodName: food['food_name'] as String? ?? 'Unknown food',
      weight: (food['serving_weight_grams'] as num?)?.toDouble(),
      calories: (food['nf_calories'] as num?)?.toDouble() ?? 0,
      protein: (food['nf_protein'] as num?)?.toDouble(),
      carbs: (food['nf_total_carbohydrate'] as num?)?.toDouble(),
      fat: (food['nf_total_fat'] as num?)?.toDouble(),
      source: source,
    );
  }

  /// Create from CalorieNinjas API response item
  factory Meal.fromCalorieNinjas(Map<String, dynamic> item, String source) {
    return Meal(
      dateTime: DateTime.now(),
      foodName: item['name'] as String? ?? 'Unknown food',
      weight: (item['serving_size_g'] as num?)?.toDouble(),
      calories: (item['calories'] as num?)?.toDouble() ?? 0,
      protein: (item['protein_g'] as num?)?.toDouble(),
      carbs: (item['carbohydrates_total_g'] as num?)?.toDouble(),
      fat: (item['fat_total_g'] as num?)?.toDouble(),
      source: source,
    );
  }

  /// Create from USDA FoodData Central API response
  factory Meal.fromUSDA(Map<String, dynamic> food, String source) {
    String name = food['description'] as String? ?? 'Unknown food';
    double? weight = (food['servingSize'] as num?)?.toDouble();
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    // Check for demo data format first
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
          case 1008:
            calories = value;
            break;
          case 1003:
            protein = value;
            break;
          case 1005:
            carbs = value;
            break;
          case 1004:
            fat = value;
            break;
        }
      }
    }

    return Meal(
      dateTime: DateTime.now(),
      foodName: name,
      weight: weight,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      source: source,
    );
  }

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_time': dateTime.millisecondsSinceEpoch,
      'food_name': foodName,
      'weight': weight,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'source': source,
    };
  }

  /// Create from database Map
  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['date_time'] as int),
      foodName: map['food_name'] as String,
      weight: (map['weight'] as num?)?.toDouble(),
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num?)?.toDouble(),
      carbs: (map['carbs'] as num?)?.toDouble(),
      fat: (map['fat'] as num?)?.toDouble(),
      source: map['source'] as String,
    );
  }

  /// Create copy with modifications
  Meal copyWith({
    String? id,
    DateTime? dateTime,
    String? foodName,
    double? weight,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? source,
  }) {
    return Meal(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      foodName: foodName ?? this.foodName,
      weight: weight ?? this.weight,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      source: source ?? this.source,
    );
  }

  /// Get date string (YYYY-MM-DD) for grouping
  String get dateStr {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// Get time string (HH:mm)
  String get timeStr {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get source icon
  String get sourceIcon {
    switch (source) {
      case 'camera':
        return '📸';
      case 'chatbot':
        return '💬';
      case 'manual':
        return '✏️';
      default:
        return '🍽️';
    }
  }

  /// Check if meal has complete macro data
  bool get hasMacros {
    return protein != null && carbs != null && fat != null;
  }

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

  @override
  String toString() {
    return 'Meal(id: $id, food: $foodName, calories: $calories, source: $source)';
  }
}
