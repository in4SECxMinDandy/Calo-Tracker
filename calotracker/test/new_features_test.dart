// Test Cases for New Features
// UI + Logic tests for Exercises and Healthy Food screens

import 'package:flutter_test/flutter_test.dart';
import 'package:calotracker/models/exercise_item.dart';
import 'package:calotracker/models/healthy_food.dart';
import 'package:calotracker/data/exercise_data.dart';
import 'package:calotracker/data/healthy_food_data.dart';

void main() {
  group('ExerciseData Tests', () {
    test('allExercises should not be empty', () {
      expect(ExerciseData.allExercises.isNotEmpty, true);
    });

    test('filterExercises by goal - weightLoss', () {
      final result = ExerciseData.filterExercises(
        goal: ExerciseGoal.weightLoss,
      );
      expect(result.every((e) => e.goal == ExerciseGoal.weightLoss), true);
    });

    test('filterExercises by goal - muscleGain', () {
      final result = ExerciseData.filterExercises(
        goal: ExerciseGoal.muscleGain,
      );
      expect(result.every((e) => e.goal == ExerciseGoal.muscleGain), true);
    });

    test('filterExercises by difficulty - easy', () {
      final result = ExerciseData.filterExercises(
        difficulty: ExerciseDifficulty.easy,
      );
      expect(
        result.every((e) => e.difficulty == ExerciseDifficulty.easy),
        true,
      );
    });

    test('filterExercises by difficulty - medium', () {
      final result = ExerciseData.filterExercises(
        difficulty: ExerciseDifficulty.medium,
      );
      expect(
        result.every((e) => e.difficulty == ExerciseDifficulty.medium),
        true,
      );
    });

    test('filterExercises by difficulty - hard', () {
      final result = ExerciseData.filterExercises(
        difficulty: ExerciseDifficulty.hard,
      );
      expect(
        result.every((e) => e.difficulty == ExerciseDifficulty.hard),
        true,
      );
    });

    test('filterExercises by location - home', () {
      final result = ExerciseData.filterExercises(
        location: ExerciseLocation.home,
      );
      expect(result.every((e) => e.location == ExerciseLocation.home), true);
    });

    test('filterExercises by location - gym', () {
      final result = ExerciseData.filterExercises(
        location: ExerciseLocation.gym,
      );
      expect(result.every((e) => e.location == ExerciseLocation.gym), true);
    });

    test('filterExercises with multiple criteria', () {
      final result = ExerciseData.filterExercises(
        goal: ExerciseGoal.weightLoss,
        difficulty: ExerciseDifficulty.easy,
        location: ExerciseLocation.home,
      );
      expect(
        result.every(
          (e) =>
              e.goal == ExerciseGoal.weightLoss &&
              e.difficulty == ExerciseDifficulty.easy &&
              e.location == ExerciseLocation.home,
        ),
        true,
      );
    });

    test('all exercises have valid YouTube URL', () {
      for (final exercise in ExerciseData.allExercises) {
        expect(
          exercise.youtubeUrl.startsWith('https://www.youtube.com/'),
          true,
          reason: 'Exercise ${exercise.name} has invalid YouTube URL',
        );
      }
    });

    test('getByGoal returns correct exercises', () {
      final weightLoss = ExerciseData.getByGoal(ExerciseGoal.weightLoss);
      final muscleGain = ExerciseData.getByGoal(ExerciseGoal.muscleGain);

      expect(weightLoss.isNotEmpty, true);
      expect(muscleGain.isNotEmpty, true);
      expect(
        weightLoss.length + muscleGain.length,
        ExerciseData.allExercises.length,
      );
    });
  });

  group('HealthyFoodData Tests', () {
    test('allFoods should not be empty', () {
      expect(HealthyFoodData.allFoods.isNotEmpty, true);
    });

    test('getByCategory returns correct foods', () {
      for (final category in FoodCategory.values) {
        final result = HealthyFoodData.getByCategory(category);
        expect(
          result.every((f) => f.category == category),
          true,
          reason: 'Category $category filter failed',
        );
      }
    });

    test('search finds matching foods', () {
      final result = HealthyFoodData.search('gà');
      expect(result.isNotEmpty, true);
      expect(result.any((f) => f.name.toLowerCase().contains('gà')), true);
    });

    test('search is case insensitive', () {
      final upper = HealthyFoodData.search('CÁ');
      final lower = HealthyFoodData.search('cá');
      expect(upper.length, lower.length);
    });

    test('getLowCalorie returns foods under limit', () {
      const limit = 100;
      final result = HealthyFoodData.getLowCalorie(maxCalories: limit);
      expect(result.every((f) => f.caloriesPer100g <= limit), true);
    });

    test('getHighProtein returns foods above limit', () {
      const limit = 15.0;
      final result = HealthyFoodData.getHighProtein(minProtein: limit);
      expect(result.every((f) => f.proteinPer100g >= limit), true);
    });

    test('all foods have valid nutrition values', () {
      for (final food in HealthyFoodData.allFoods) {
        expect(
          food.caloriesPer100g >= 0,
          true,
          reason: '${food.name} has negative calories',
        );
        expect(
          food.proteinPer100g >= 0,
          true,
          reason: '${food.name} has negative protein',
        );
        expect(
          food.carbsPer100g >= 0,
          true,
          reason: '${food.name} has negative carbs',
        );
        expect(
          food.fatPer100g >= 0,
          true,
          reason: '${food.name} has negative fat',
        );
      }
    });

    test('all foods have non-empty benefits', () {
      for (final food in HealthyFoodData.allFoods) {
        expect(
          food.benefits.isNotEmpty,
          true,
          reason: '${food.name} has empty benefits',
        );
      }
    });
  });

  group('ExerciseItem Model Tests', () {
    test('formattedDuration for minutes', () {
      const exercise = ExerciseItem(
        id: 'test',
        name: 'Test',
        description: 'Test',
        muscleGroup: 'Test',
        durationMinutes: 30,
        sets: 3,
        reps: 10,
        difficulty: ExerciseDifficulty.easy,
        location: ExerciseLocation.home,
        goal: ExerciseGoal.weightLoss,
        youtubeUrl: 'https://www.youtube.com/test',
      );
      expect(exercise.formattedDuration, '30 phút');
    });

    test('formattedDuration for hours', () {
      const exercise = ExerciseItem(
        id: 'test',
        name: 'Test',
        description: 'Test',
        muscleGroup: 'Test',
        durationMinutes: 90,
        sets: 3,
        reps: 10,
        difficulty: ExerciseDifficulty.easy,
        location: ExerciseLocation.home,
        goal: ExerciseGoal.weightLoss,
        youtubeUrl: 'https://www.youtube.com/test',
      );
      expect(exercise.formattedDuration, '1h 30p');
    });

    test('setsRepsFormatted', () {
      const exercise = ExerciseItem(
        id: 'test',
        name: 'Test',
        description: 'Test',
        muscleGroup: 'Test',
        durationMinutes: 30,
        sets: 4,
        reps: 12,
        difficulty: ExerciseDifficulty.easy,
        location: ExerciseLocation.home,
        goal: ExerciseGoal.weightLoss,
        youtubeUrl: 'https://www.youtube.com/test',
      );
      expect(exercise.setsRepsFormatted, '4 hiệp × 12 lần');
    });

    test('totalCalories calculation', () {
      const exercise = ExerciseItem(
        id: 'test',
        name: 'Test',
        description: 'Test',
        muscleGroup: 'Test',
        durationMinutes: 30,
        sets: 5,
        reps: 10,
        difficulty: ExerciseDifficulty.easy,
        location: ExerciseLocation.home,
        goal: ExerciseGoal.weightLoss,
        youtubeUrl: 'https://www.youtube.com/test',
        caloriesPerSet: 20,
      );
      expect(exercise.totalCalories, 100);
    });
  });

  group('HealthyFood Model Tests', () {
    test('macrosFormatted', () {
      const food = HealthyFood(
        id: 'test',
        name: 'Test',
        description: 'Test',
        category: FoodCategory.protein,
        caloriesPer100g: 100,
        proteinPer100g: 20,
        carbsPer100g: 5,
        fatPer100g: 3,
        benefits: 'Test benefits',
      );
      expect(food.macrosFormatted, 'P: 20.0g | C: 5.0g | F: 3.0g');
    });
  });

  group('Enum Label Tests', () {
    test('ExerciseDifficulty labels', () {
      expect(ExerciseDifficulty.easy.label, 'Dễ');
      expect(ExerciseDifficulty.medium.label, 'Trung bình');
      expect(ExerciseDifficulty.hard.label, 'Khó');
    });

    test('ExerciseLocation labels', () {
      expect(ExerciseLocation.home.label, 'Tại nhà');
      expect(ExerciseLocation.gym.label, 'Phòng gym');
    });

    test('ExerciseGoal labels', () {
      expect(ExerciseGoal.weightLoss.label, 'Giảm cân');
      expect(ExerciseGoal.muscleGain.label, 'Tăng cơ');
    });

    test('FoodCategory labels', () {
      expect(FoodCategory.protein.label, 'Protein');
      expect(FoodCategory.carbs.label, 'Tinh bột');
      expect(FoodCategory.vegetables.label, 'Rau củ');
      expect(FoodCategory.fruits.label, 'Trái cây');
      expect(FoodCategory.dairy.label, 'Sữa');
      expect(FoodCategory.nuts.label, 'Hạt');
      expect(FoodCategory.beverages.label, 'Đồ uống');
    });
  });
}

/*
=================================================================
UI TEST CASES - Manual Testing Checklist
=================================================================

## Exercises Screen Tests

### TC-EX-001: Goal Selection
- [ ] Tap on "Giảm cân" goal card
- [ ] Verify only weight loss exercises are shown
- [ ] Tap again to deselect
- [ ] Verify all exercises are shown
- [ ] Repeat for "Tăng cơ" goal

### TC-EX-002: Difficulty Filter
- [ ] Select "Dễ" from difficulty dropdown
- [ ] Verify exercises have green "Dễ" tags
- [ ] Select "Trung bình"
- [ ] Verify exercises have orange tags
- [ ] Select "Khó"
- [ ] Verify exercises have red tags
- [ ] Select "Tất cả" to reset

### TC-EX-003: Location Filter
- [ ] Select "Tại nhà" from location dropdown
- [ ] Verify home icon on all exercise cards
- [ ] Select "Phòng gym"
- [ ] Verify gym icon on all exercise cards

### TC-EX-004: Combined Filters
- [ ] Select Goal: "Giảm cân"
- [ ] Select Difficulty: "Trung bình"
- [ ] Select Location: "Tại nhà"
- [ ] Verify results match all criteria
- [ ] Verify results count is correct

### TC-EX-005: YouTube Link
- [ ] Tap "Xem hướng dẫn YouTube" button
- [ ] Verify YouTube app/browser opens
- [ ] Verify correct video is loaded

### TC-EX-006: Clear Filters
- [ ] Apply multiple filters
- [ ] Tap clear filters button (X icon)
- [ ] Verify all filters are reset
- [ ] Verify all exercises are shown

### TC-EX-007: Empty State
- [ ] Apply filters that return no results
- [ ] Verify "Không tìm thấy bài tập" message
- [ ] Verify "Xóa bộ lọc" button works

## Healthy Food Screen Tests

### TC-HF-001: Category Filter
- [ ] Tap on each category chip
- [ ] Verify only foods of that category are shown
- [ ] Tap same chip again to deselect
- [ ] Verify all foods are shown

### TC-HF-002: Search Function
- [ ] Type "gà" in search box
- [ ] Verify "Ức gà" appears in results
- [ ] Clear search
- [ ] Verify all foods appear

### TC-HF-003: Quick Filters
- [ ] Tap "Ít calo" button
- [ ] Verify low-calorie foods are shown
- [ ] Tap "Giàu Protein" button
- [ ] Verify high-protein foods are shown

### TC-HF-004: Food Detail Modal
- [ ] Tap on any food card
- [ ] Verify modal appears with details
- [ ] Verify nutrition info is correct
- [ ] Verify benefits section shows
- [ ] Verify tips section shows (if available)
- [ ] Drag to dismiss modal

### TC-HF-005: Category + Search Combined
- [ ] Select "Protein" category
- [ ] Search for "cá"
- [ ] Verify results are in Protein category AND contain "cá"

## Home Screen Tests

### TC-HOME-001: Camera Button Location
- [ ] Verify camera button is in header (top right area)
- [ ] Verify button has green gradient
- [ ] Tap button
- [ ] Verify camera screen opens

### TC-HOME-002: Healthy Food Card
- [ ] Verify "Healthy Food" card exists
- [ ] Verify green gradient color
- [ ] Tap card
- [ ] Verify Healthy Food screen opens

### TC-HOME-003: Bài tập Card
- [ ] Verify "Bài tập" card exists
- [ ] Verify red gradient color
- [ ] Tap card
- [ ] Verify Exercises screen opens

### TC-HOME-004: Layout Balance
- [ ] Verify 6 action cards in 3 rows of 2
- [ ] Verify consistent spacing
- [ ] Verify no placeholder cards

=================================================================
*/
