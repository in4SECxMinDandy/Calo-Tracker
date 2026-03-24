// Lưu kết quả nhận diện món ăn qua ảnh vào SQLite (Lịch sử) — atomic batch + metadata
import 'dart:convert';

import '../models/chat_message.dart';
import '../models/meal.dart';
import 'database_service.dart';
import 'food_recognition_service.dart';

/// Kết quả thao tác lưu sau khi quét ảnh
class FoodRecognitionPersistenceResult {
  final bool success;
  final int mealsSaved;
  final String? error;

  const FoodRecognitionPersistenceResult._({
    required this.success,
    this.mealsSaved = 0,
    this.error,
  });

  factory FoodRecognitionPersistenceResult.ok(int count) =>
      FoodRecognitionPersistenceResult._(success: true, mealsSaved: count);

  factory FoodRecognitionPersistenceResult.fail(String message) =>
      FoodRecognitionPersistenceResult._(
        success: false,
        error: message,
      );
}

abstract final class FoodRecognitionPersistence {
  /// Build danh sách [Meal] từ kết quả dinh dưỡng + nhận diện (pure — dễ test).
  static List<Meal> buildMealsFromScan({
    required NutritionData nutritionData,
    required List<RecognizedFood> recognizedFoods,
    String? imagePath,
  }) {
    final n = nutritionData.foods.length;
    if (n == 0) return [];

    final metaMap = <String, dynamic>{
      'source': 'ai_food_scan',
      'saved_at': DateTime.now().toIso8601String(),
      if (imagePath != null && imagePath.isNotEmpty) 'image_path': imagePath,
      'recognized': [
        for (final f in recognizedFoods)
          <String, dynamic>{
            'name': f.name,
            'name_en': f.nameEn,
            'confidence': f.confidence,
            'estimated_weight_g': f.estimatedWeight,
          },
      ],
      'totals': <String, dynamic>{
        'calories': nutritionData.calories,
        'protein': nutritionData.protein,
        'carbs': nutritionData.carbs,
        'fat': nutritionData.fat,
      },
    };
    final metaJson = jsonEncode(metaMap);

    final pShare = n > 0 && nutritionData.protein != null
        ? nutritionData.protein! / n
        : null;
    final cShare = n > 0 && nutritionData.carbs != null
        ? nutritionData.carbs! / n
        : null;
    final fShare = n > 0 && nutritionData.fat != null
        ? nutritionData.fat! / n
        : null;

    return [
      for (var i = 0; i < n; i++)
        Meal(
          dateTime: DateTime.now(),
          foodName: nutritionData.foods[i].name,
          weight: nutritionData.foods[i].weight,
          calories: nutritionData.foods[i].calories,
          protein: pShare,
          carbs: cShare,
          fat: fShare,
          source: 'camera',
          notes: i == 0 ? metaJson : null,
        ),
    ];
  }

  /// Lưu vào DB trong một transaction; không lưu nếu danh sách rỗng.
  static Future<FoodRecognitionPersistenceResult> saveScanToHistory({
    required NutritionData nutritionData,
    required List<RecognizedFood> recognizedFoods,
    String? imagePath,
  }) async {
    try {
      final meals = buildMealsFromScan(
        nutritionData: nutritionData,
        recognizedFoods: recognizedFoods,
        imagePath: imagePath,
      );
      if (meals.isEmpty) {
        return FoodRecognitionPersistenceResult.fail('Không có món để lưu');
      }
      await DatabaseService.insertMealsBatch(meals);
      return FoodRecognitionPersistenceResult.ok(meals.length);
    } catch (e, st) {
      assert(() {
        // ignore: avoid_print
        print('FoodRecognitionPersistence.saveScanToHistory: $e\n$st');
        return true;
      }());
      return FoodRecognitionPersistenceResult.fail('$e');
    }
  }
}
