// FoodRecognitionPersistence unit tests
// Tests: buildMealsFromScan, saveScanToHistory, edge cases
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:calotracker/models/chat_message.dart';
import 'package:calotracker/models/meal.dart';
import 'package:calotracker/services/food_recognition_persistence.dart';
import 'package:calotracker/services/food_recognition_service.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

NutritionData makeNutrition({
  List<FoodItem>? foods,
  double calories = 300,
  double? protein,
  double? carbs,
  double? fat,
}) {
  return NutritionData(
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
    foods: foods ??
        [
          FoodItem(name: 'Trứng luộc', calories: 78, weight: 50),
        ],
  );
}

RecognizedFood makeRecognizedFood({
  String name = 'Trứng gà luộc',
  double confidence = 0.92,
  double weight = 100,
}) {
  return RecognizedFood(
    name: name,
    nameEn: name,
    estimatedWeight: weight,
    confidence: confidence,
  );
}

// ── Tests ────────────────────────────────────────────────────────────────

void main() {
  // ── Unit: buildMealsFromScan ──────────────────────────────────────────

  group('FoodRecognitionPersistence.buildMealsFromScan (unit)', () {
    test('returns empty list when nutritionData.foods is empty', () {
      final result = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: NutritionData(calories: 0, foods: []),
        recognizedFoods: [],
      );
      expect(result, isEmpty);
    });

    test('maps single food correctly', () {
      final nutrition = makeNutrition(
        calories: 200,
        protein: 12,
        carbs: 20,
        fat: 8,
        foods: [
          FoodItem(name: 'Cơm trắng', calories: 200, weight: 150),
        ],
      );
      final recognized = [makeRecognizedFood(name: 'Cơm trắng')];

      final meals = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: nutrition,
        recognizedFoods: recognized,
      );

      expect(meals.length, 1);
      expect(meals[0].foodName, 'Cơm trắng');
      expect(meals[0].calories, 200);
      expect(meals[0].source, 'camera');
      expect(meals[0].weight, 150);
      expect(meals[0].notes, isNotNull);

      final meta = jsonDecode(meals[0].notes!);
      expect(meta['source'], 'ai_food_scan');
      expect(meta['recognized'], isA<List>());
    });

    test('distributes total macros across foods', () {
      final nutrition = makeNutrition(
        calories: 600,
        protein: 30,
        carbs: 80,
        fat: 20,
        foods: [
          FoodItem(name: 'Món A', calories: 300, weight: 200),
          FoodItem(name: 'Món B', calories: 300, weight: 150),
        ],
      );
      final recognized = [
        makeRecognizedFood(name: 'Món A'),
        makeRecognizedFood(name: 'Món B'),
      ];

      final meals = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: nutrition,
        recognizedFoods: recognized,
      );

      expect(meals.length, 2);
      // Mỗi món nhận 1/2 macro tổng
      expect(meals[0].protein, 15);
      expect(meals[0].carbs, 40);
      expect(meals[0].fat, 10);
      expect(meals[1].protein, 15);
      expect(meals[1].carbs, 40);
      expect(meals[1].fat, 10);
    });

    test('includes imagePath in metadata when provided', () {
      final meals = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: makeNutrition(
          foods: [FoodItem(name: 'Test', calories: 50, weight: 50)],
        ),
        recognizedFoods: [makeRecognizedFood()],
        imagePath: '/storage/photos/food123.jpg',
      );
      final meta = jsonDecode(meals[0].notes!);
      expect(meta['image_path'], '/storage/photos/food123.jpg');
    });

    test('imagePath is omitted from metadata when null', () {
      final meals = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: makeNutrition(
          foods: [FoodItem(name: 'Test', calories: 50, weight: 50)],
        ),
        recognizedFoods: [makeRecognizedFood()],
        imagePath: null,
      );
      final meta = jsonDecode(meals[0].notes!);
      expect(meta.containsKey('image_path'), false);
    });

    test('confidence and weight appear in recognized list', () {
      final meals = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: makeNutrition(
          foods: [FoodItem(name: 'Salad', calories: 80, weight: 120)],
        ),
        recognizedFoods: [
          makeRecognizedFood(
            name: 'Salad',
            confidence: 0.88,
            weight: 120,
          ),
        ],
      );
      final meta = jsonDecode(meals[0].notes!);
      final recognized = meta['recognized'] as List;
      expect(recognized[0]['confidence'], 0.88);
      expect(recognized[0]['estimated_weight_g'], 120);
    });

    test('only first meal has notes metadata (others null)', () {
      final nutrition = makeNutrition(
        calories: 600,
        protein: 30,
        carbs: 80,
        fat: 20,
        foods: [
          FoodItem(name: 'A', calories: 300, weight: 200),
          FoodItem(name: 'B', calories: 300, weight: 150),
        ],
      );
      final recognized = [
        makeRecognizedFood(name: 'A'),
        makeRecognizedFood(name: 'B'),
      ];

      final meals = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: nutrition,
        recognizedFoods: recognized,
      );

      expect(meals[0].notes, isNotNull);
      expect(meals[1].notes, isNull);
    });

    test('totals field in notes JSON', () {
      final meals = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: makeNutrition(
          calories: 450,
          protein: 30,
          carbs: 60,
          fat: 15,
          foods: [FoodItem(name: 'X', calories: 450, weight: 300)],
        ),
        recognizedFoods: [makeRecognizedFood(name: 'X')],
      );
      final meta = jsonDecode(meals[0].notes!);
      expect(meta['totals']['calories'], 450);
      expect(meta['totals']['protein'], 30);
      expect(meta['totals']['carbs'], 60);
      expect(meta['totals']['fat'], 15);
    });
  });

  // ── Unit: saveScanToHistory ───────────────────────────────────────────

  group('FoodRecognitionPersistence.saveScanToHistory (unit)', () {
    test('Empty foods list → returns fail result', () async {
      final result = await FoodRecognitionPersistence.saveScanToHistory(
        nutritionData: NutritionData(calories: 0, foods: []),
        recognizedFoods: [],
      );
      expect(result.success, false);
      expect(result.error, contains('Không có món'));
    });
  });

  // ── Edge cases ────────────────────────────────────────────────────────

  group('Edge cases', () {
    test('null macros are gracefully distributed (no crash)', () {
      final nutrition = NutritionData(
        calories: 100,
        protein: null,
        carbs: null,
        fat: null,
        foods: [
          FoodItem(name: 'Snack', calories: 100, weight: 30),
        ],
      );
      final meals = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: nutrition,
        recognizedFoods: [makeRecognizedFood(name: 'Snack')],
      );
      expect(meals.length, 1);
      expect(meals[0].protein, isNull);
      expect(meals[0].carbs, isNull);
      expect(meals[0].fat, isNull);
    });

    test('single food gets full macros', () {
      final nutrition = makeNutrition(
        calories: 400,
        protein: 40,
        carbs: 40,
        fat: 16,
        foods: [FoodItem(name: 'Combo', calories: 400, weight: 300)],
      );
      final meals = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: nutrition,
        recognizedFoods: [makeRecognizedFood(name: 'Combo')],
      );
      expect(meals[0].protein, 40);
      expect(meals[0].carbs, 40);
      expect(meals[0].fat, 16);
    });

    test('Meal.notes round-trip through toMap/fromMap JSON', () {
      final meals = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: makeNutrition(
          calories: 200,
          foods: [FoodItem(name: 'X', calories: 200, weight: 100)],
        ),
        recognizedFoods: [
          makeRecognizedFood(
            name: 'X',
            confidence: 0.95,
            weight: 100,
          ),
        ],
        imagePath: '/path/to/img.jpg',
      );

      // Decode notes JSON
      final notes = jsonDecode(meals[0].notes!);
      expect(notes['source'], 'ai_food_scan');
      expect(notes['recognized'][0]['confidence'], 0.95);
      expect(notes['image_path'], '/path/to/img.jpg');

      // Round-trip through toMap/fromMap
      final mealMap = meals[0].toMap();
      final meal = Meal.fromMap(mealMap);
      expect(meal.notes, isNotNull);

      final notes2 = jsonDecode(meal.notes!);
      expect(notes2['source'], 'ai_food_scan');
    });

    test('All 4 fields present in notes JSON (offline safe)', () {
      final meals = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: makeNutrition(
          calories: 500,
          protein: 50,
          carbs: 60,
          fat: 18,
          foods: [FoodItem(name: 'Y', calories: 500, weight: 250)],
        ),
        recognizedFoods: [
          makeRecognizedFood(
            name: 'Y',
            confidence: 0.99,
            weight: 250,
          ),
        ],
        imagePath: null,
      );
      final meta = jsonDecode(meals[0].notes!);
      // Bắt buộc phải có đủ 4 trường
      expect(meta['source'], isNotNull);
      expect(meta['saved_at'], isNotNull);
      expect(meta['recognized'], isA<List>());
      expect(meta['totals'], isNotNull);
    });

    test('source field is always camera for scanned meals', () {
      final meals = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: makeNutrition(
          calories: 100,
          foods: [FoodItem(name: 'Z', calories: 100, weight: 50)],
        ),
        recognizedFoods: [makeRecognizedFood(name: 'Z')],
      );
      expect(meals.every((m) => m.source == 'camera'), isTrue);
    });

    test('User presses back during scan → no persist flag set (by design)', () {
      // This tests that buildMealsFromScan is a pure function that doesn't
      // modify any global state. Call it twice → same result.
      final nutrition = makeNutrition(
        calories: 250,
        foods: [FoodItem(name: 'A', calories: 250, weight: 100)],
      );
      final recognized = [makeRecognizedFood(name: 'A')];

      final result1 = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: nutrition,
        recognizedFoods: recognized,
      );
      final result2 = FoodRecognitionPersistence.buildMealsFromScan(
        nutritionData: nutrition,
        recognizedFoods: recognized,
      );

      expect(result1.length, result2.length);
      expect(result1[0].foodName, result2[0].foodName);
      expect(result1[0].calories, result2[0].calories);
    });
  });
}
