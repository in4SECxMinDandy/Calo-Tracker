import 'package:flutter_test/flutter_test.dart';
import 'package:calotracker/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('should create UserProfile with factory method', () {
      // Arrange & Act
      final profile = UserProfile.create(
        name: 'John Doe',
        height: 175.0,
        weight: 70.0,
        goal: 'maintain',
      );

      // Assert
      expect(profile.name, 'John Doe');
      expect(profile.height, 175.0);
      expect(profile.weight, 70.0);
      expect(profile.goal, 'maintain');
      expect(profile.bmr, greaterThan(0));
      expect(profile.dailyTarget, greaterThan(0));
    });

    test('should calculate BMR correctly', () {
      // Arrange
      const weight = 70.0;
      const height = 175.0;

      // Act
      final bmr = UserProfile.calculateBMR(weight, height);

      // Assert - Using simplified equation: BMR = 10 * weight + 6.25 * height - 78
      final expectedBMR = 10 * weight + 6.25 * height - 78;
      expect(bmr, closeTo(expectedBMR, 0.1));
    });

    test('should calculate daily target for weight loss', () {
      // Arrange
      const bmr = 1500.0;

      // Act
      final target = UserProfile.calculateDailyTarget(bmr, 'lose');

      // Assert - 20% deficit
      expect(target, closeTo(bmr * 0.8, 0.1));
    });

    test('should calculate daily target for weight gain', () {
      // Arrange
      const bmr = 1500.0;

      // Act
      final target = UserProfile.calculateDailyTarget(bmr, 'gain');

      // Assert - 20% surplus
      expect(target, closeTo(bmr * 1.2, 0.1));
    });

    test('should calculate daily target for maintenance', () {
      // Arrange
      const bmr = 1500.0;

      // Act
      final target = UserProfile.calculateDailyTarget(bmr, 'maintain');

      // Assert - No change
      expect(target, bmr);
    });

    test('should auto-calculate BMR and dailyTarget with create factory', () {
      // Arrange & Act
      final profile = UserProfile.create(
        name: 'Test User',
        height: 175.0,
        weight: 70.0,
        goal: 'lose',
      );

      // Assert
      final expectedBMR = UserProfile.calculateBMR(70.0, 175.0);
      final expectedTarget = UserProfile.calculateDailyTarget(
        expectedBMR,
        'lose',
      );

      expect(profile.bmr, closeTo(expectedBMR, 0.1));
      expect(profile.dailyTarget, closeTo(expectedTarget, 0.1));
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final profile = UserProfile.create(
        name: 'Test User',
        height: 175.0,
        weight: 70.0,
        goal: 'lose',
      );

      // Act
      final map = profile.toMap();

      // Assert
      expect(map['name'], 'Test User');
      expect(map['height'], 175.0);
      expect(map['weight'], 70.0);
      expect(map['goal'], 'lose');
      expect(map['bmr'], isNotNull);
      expect(map['daily_target'], isNotNull);
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final now = DateTime.now();
      final map = {
        'name': 'Test User',
        'height': 175.0,
        'weight': 70.0,
        'goal': 'gain',
        'bmr': 1500.0,
        'daily_target': 1800.0,
        'created_at': now.millisecondsSinceEpoch,
        'country': 'VN',
        'language': 'vi',
      };

      // Act
      final profile = UserProfile.fromMap(map);

      // Assert
      expect(profile.name, 'Test User');
      expect(profile.height, 175.0);
      expect(profile.weight, 70.0);
      expect(profile.goal, 'gain');
      expect(profile.bmr, 1500.0);
      expect(profile.dailyTarget, 1800.0);
    });

    test('should handle serialization round-trip', () {
      // Arrange
      final original = UserProfile.create(
        name: 'Round Trip Test',
        height: 180.0,
        weight: 75.0,
        goal: 'maintain',
      );

      // Act
      final map = original.toMap();
      final deserialized = UserProfile.fromMap(map);

      // Assert
      expect(deserialized.name, original.name);
      expect(deserialized.height, original.height);
      expect(deserialized.weight, original.weight);
      expect(deserialized.goal, original.goal);
      expect(deserialized.bmr, closeTo(original.bmr, 0.1));
      expect(deserialized.dailyTarget, closeTo(original.dailyTarget, 0.1));
    });

    test('should create profile with default country and language', () {
      // Act
      final profile = UserProfile.create(
        name: 'Test',
        height: 170.0,
        weight: 70.0,
        goal: 'maintain',
      );

      // Assert
      expect(profile.country, 'VN');
      expect(profile.language, 'vi');
    });

    test('should use copyWith to update fields', () {
      // Arrange
      final original = UserProfile.create(
        name: 'Original',
        height: 170.0,
        weight: 70.0,
        goal: 'maintain',
      );

      // Act
      final updated = original.copyWith(name: 'Updated', weight: 75.0);

      // Assert
      expect(updated.name, 'Updated');
      expect(updated.weight, 75.0);
      expect(updated.height, original.height); // Unchanged
      expect(updated.goal, original.goal); // Unchanged
    });

    test('should return correct goal display names', () {
      // Arrange
      final lose = UserProfile.create(
        name: 'Test',
        height: 170.0,
        weight: 80.0,
        goal: 'lose',
      );

      final gain = UserProfile.create(
        name: 'Test',
        height: 170.0,
        weight: 60.0,
        goal: 'gain',
      );

      final maintain = UserProfile.create(
        name: 'Test',
        height: 170.0,
        weight: 70.0,
        goal: 'maintain',
      );

      // Assert
      expect(lose.goalDisplayName, 'Giảm cân');
      expect(gain.goalDisplayName, 'Tăng cân');
      expect(maintain.goalDisplayName, 'Duy trì');
    });
  });
}
