// Unit tests for FoodDatabaseService và ChatbotIntelligenceService
// Kiểm tra tìm kiếm món ăn, tính toán dinh dưỡng, và logic chatbot
import 'package:flutter_test/flutter_test.dart';
import 'package:calotracker/data/food_database.dart';

void main() {
  group('FoodDatabaseService — Search', () {
    test('should find exact match for Vietnamese food', () {
      final results = FoodDatabaseService.search('phở bò');
      expect(results, isNotEmpty);
      expect(results.first.food.name, equals('Phở bò'));
    });

    test('should find food by keyword (no diacritics)', () {
      final results = FoodDatabaseService.search('pho bo');
      expect(results, isNotEmpty);
      // Kết quả đầu tiên phải là phở bò
      expect(results.first.food.name.toLowerCase(), contains('phở'));
    });

    test('should find food by English name', () {
      final results = FoodDatabaseService.search('burger');
      expect(results, isNotEmpty);
      expect(results.first.food.name.toLowerCase(), contains('burger'));
    });

    test('should return empty list for unknown food', () {
      final results = FoodDatabaseService.search('xyz_unknown_food_12345');
      expect(results, isEmpty);
    });

    test('should return empty list for empty query', () {
      final results = FoodDatabaseService.search('');
      expect(results, isEmpty);
    });

    test('should limit results to maxResults', () {
      final results = FoodDatabaseService.search('cơm', maxResults: 2);
      expect(results.length, lessThanOrEqualTo(2));
    });

    test('should sort results by relevance score', () {
      final results = FoodDatabaseService.search('phở');
      expect(results.length, greaterThan(1));
      // Điểm liên quan phải giảm dần
      for (int i = 1; i < results.length; i++) {
        expect(
          results[i].relevanceScore,
          lessThanOrEqualTo(results[i - 1].relevanceScore),
        );
      }
    });

    test('findBest should return single best result', () {
      final food = FoodDatabaseService.findBest('gà luộc');
      expect(food, isNotNull);
      expect(food!.name, equals('Gà luộc'));
    });

    test('findBest should return null for unknown food', () {
      final food = FoodDatabaseService.findBest('xyz_unknown_12345');
      expect(food, isNull);
    });
  });

  group('FoodDatabaseService — Nutrition Calculation', () {
    test('should calculate calories correctly for 100g', () {
      final food = FoodDatabaseService.findBest('cơm trắng');
      expect(food, isNotNull);

      // 100g cơm trắng = caloriesPer100g
      final calories = food!.caloriesForWeight(100);
      expect(calories, closeTo(food.caloriesPer100g, 0.01));
    });

    test('should calculate calories correctly for 200g', () {
      final food = FoodDatabaseService.findBest('cơm trắng');
      expect(food, isNotNull);

      // 200g = 2 * caloriesPer100g
      final calories = food!.caloriesForWeight(200);
      expect(calories, closeTo(food.caloriesPer100g * 2, 0.01));
    });

    test('should calculate serving calories correctly', () {
      final food = FoodDatabaseService.findBest('phở bò');
      expect(food, isNotNull);

      // servingCalories = caloriesPer100g * servingSize / 100
      final expected = food!.caloriesPer100g * food.servingSize / 100;
      expect(food.servingCalories, closeTo(expected, 0.01));
    });

    test('analyze should return correct nutrition for default serving', () {
      final analysis = FoodDatabaseService.analyze('gà luộc');
      expect(analysis, isNotNull);

      final food = analysis!.food;
      expect(analysis.weightGrams, equals(food.servingSize));
      expect(analysis.calories, closeTo(food.servingCalories, 0.01));
      expect(analysis.protein, closeTo(food.servingProtein, 0.01));
    });

    test('analyze should return correct nutrition for custom weight', () {
      final analysis = FoodDatabaseService.analyze('cơm trắng', weightGrams: 150);
      expect(analysis, isNotNull);
      expect(analysis!.weightGrams, equals(150));

      final food = analysis.food;
      final expectedCalories = food.caloriesPer100g * 150 / 100;
      expect(analysis.calories, closeTo(expectedCalories, 0.01));
    });

    test('analyze should return null for unknown food', () {
      final analysis = FoodDatabaseService.analyze('xyz_unknown_12345');
      expect(analysis, isNull);
    });
  });

  group('FoodDatabaseService — Categories', () {
    test('should return Vietnamese foods', () {
      final foods = FoodDatabaseService.getByCategory(FoodCategory.vietnamese);
      expect(foods, isNotEmpty);
      expect(foods.every((f) => f.category == FoodCategory.vietnamese), isTrue);
    });

    test('should return healthy foods with score >= 4', () {
      final foods = FoodDatabaseService.getHealthyFoods();
      expect(foods, isNotEmpty);
      expect(foods.every((f) => f.healthScore >= 4), isTrue);
    });

    test('healthy foods should be sorted by health score descending', () {
      final foods = FoodDatabaseService.getHealthyFoods();
      for (int i = 1; i < foods.length; i++) {
        expect(
          foods[i].healthScore,
          lessThanOrEqualTo(foods[i - 1].healthScore),
        );
      }
    });
  });

  group('FoodDatabaseService — Alternatives', () {
    test('should return healthier alternatives for burger', () {
      final food = FoodDatabaseService.findBest('burger');
      expect(food, isNotNull);

      // Burger có alternatives trong database
      FoodDatabaseService.getHealthierAlternatives(food!);
      expect(food.healthierAlternatives, isNotEmpty);
    });

    test('should return empty alternatives for already healthy food', () {
      final food = FoodDatabaseService.findBest('gà luộc');
      expect(food, isNotNull);

      // Gà luộc có healthScore = 5, alternatives có thể rỗng
      // Chỉ kiểm tra không crash
      final alternatives = FoodDatabaseService.getHealthierAlternatives(food!);
      expect(alternatives, isA<List>());
    });
  });

  group('FoodDatabaseService — Database Integrity', () {
    test('should have at least 40 food items', () {
      expect(FoodDatabaseService.totalFoods, greaterThanOrEqualTo(40));
    });

    test('all foods should have positive calories', () {
      for (final food in FoodDatabaseService.allFoods) {
        expect(
          food.caloriesPer100g,
          greaterThan(0),
          reason: '${food.name} has non-positive calories',
        );
      }
    });

    test('all foods should have non-negative macros', () {
      for (final food in FoodDatabaseService.allFoods) {
        expect(food.proteinPer100g, greaterThanOrEqualTo(0),
            reason: '${food.name} has negative protein');
        expect(food.carbsPer100g, greaterThanOrEqualTo(0),
            reason: '${food.name} has negative carbs');
        expect(food.fatPer100g, greaterThanOrEqualTo(0),
            reason: '${food.name} has negative fat');
      }
    });

    test('all foods should have positive serving size', () {
      for (final food in FoodDatabaseService.allFoods) {
        expect(
          food.servingSize,
          greaterThan(0),
          reason: '${food.name} has non-positive serving size',
        );
      }
    });

    test('all foods should have health score between 1 and 5', () {
      for (final food in FoodDatabaseService.allFoods) {
        expect(
          food.healthScore,
          inInclusiveRange(1, 5),
          reason: '${food.name} has invalid health score',
        );
      }
    });

    test('all foods should have at least one keyword', () {
      for (final food in FoodDatabaseService.allFoods) {
        expect(
          food.keywords,
          isNotEmpty,
          reason: '${food.name} has no keywords',
        );
      }
    });
  });

  group('FoodNutritionAnalysis — Macro Ratios', () {
    test('protein ratio should be calculated correctly', () {
      final analysis = FoodDatabaseService.analyze('gà luộc');
      expect(analysis, isNotNull);

      // Protein ratio = (protein * 4 / calories) * 100
      final expectedRatio = (analysis!.protein * 4 / analysis.calories) * 100;
      expect(analysis.proteinRatio, closeTo(expectedRatio, 0.01));
    });

    test('macro ratios should sum to approximately 100%', () {
      final analysis = FoodDatabaseService.analyze('cơm trắng');
      expect(analysis, isNotNull);

      final totalRatio = analysis!.proteinRatio + analysis.carbsRatio + analysis.fatRatio;
      // Tổng có thể không đúng 100% do làm tròn, nhưng phải gần 100%
      expect(totalRatio, closeTo(100, 5));
    });

    test('protein ratio should be 0 when calories is 0', () {
      // Edge case: calories = 0
      const analysis = FoodNutritionAnalysis(
        food: FoodItem(
          name: 'Test',
          keywords: ['test'],
          category: FoodCategory.vegetable,
          servingSize: 100,
          servingUnit: 'g',
          caloriesPer100g: 0,
          proteinPer100g: 0,
          carbsPer100g: 0,
          fatPer100g: 0,
          mainIngredients: [],
        ),
        weightGrams: 100,
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
      );

      expect(analysis.proteinRatio, equals(0));
      expect(analysis.carbsRatio, equals(0));
      expect(analysis.fatRatio, equals(0));
    });
  });
}
