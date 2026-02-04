import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calotracker/services/storage_service.dart';
import 'package:calotracker/models/user_profile.dart';

void main() {
  group('StorageService Tests', () {
    setUp(() async {
      // Initialize with mock data
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
    });

    tearDown(() async {
      await StorageService.clearAll();
    });

    test('should save and retrieve user profile', () async {
      // Arrange
      final profile = UserProfile.create(
        name: 'Test User',
        height: 170.0,
        weight: 70.0,
        goal: 'maintain',
      );

      // Act
      await StorageService.saveUserProfile(profile);
      final retrieved = StorageService.getUserProfile();

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.name, profile.name);
      expect(retrieved.height, profile.height);
      expect(retrieved.weight, profile.weight);
    });

    test('should return null when no profile exists', () {
      // Act
      final profile = StorageService.getUserProfile();

      // Assert
      expect(profile, isNull);
    });

    test('should delete user profile', () async {
      // Arrange
      final profile = UserProfile.create(
        name: 'Test User',
        height: 170.0,
        weight: 70.0,
        goal: 'maintain',
      );
      await StorageService.saveUserProfile(profile);

      // Act
      await StorageService.deleteUserProfile();
      final retrieved = StorageService.getUserProfile();

      // Assert
      expect(retrieved, isNull);
    });

    test('should check if user profile exists', () async {
      // Arrange
      final profile = UserProfile.create(
        name: 'Test User',
        height: 170.0,
        weight: 70.0,
        goal: 'maintain',
      );

      // Act - before saving
      expect(StorageService.hasUserProfile(), isFalse);

      // Act - after saving
      await StorageService.saveUserProfile(profile);
      expect(StorageService.hasUserProfile(), isTrue);
    });

    test('should save and retrieve dark mode preference', () async {
      // Act
      await StorageService.setDarkMode(true);
      expect(StorageService.isDarkMode(), isTrue);

      await StorageService.setDarkMode(false);
      expect(StorageService.isDarkMode(), isFalse);
    });

    test('should save and retrieve language preference', () async {
      // Act
      await StorageService.setLanguage('en');
      expect(StorageService.getLanguage(), 'en');

      // Default should be 'vi'
      await StorageService.clearAll();
      await StorageService.init();
      expect(StorageService.getLanguage(), 'vi');
    });

    test('should save and retrieve onboarding status', () async {
      // Act
      expect(StorageService.isOnboardingComplete(), isFalse);

      await StorageService.setOnboardingComplete(true);
      expect(StorageService.isOnboardingComplete(), isTrue);
    });

    test('should save and retrieve notification settings', () async {
      // Default should be true
      expect(StorageService.isNotificationsEnabled(), isTrue);

      // Act
      await StorageService.setNotificationsEnabled(false);
      expect(StorageService.isNotificationsEnabled(), isFalse);
    });

    test('should clear all preferences', () async {
      // Arrange
      final profile = UserProfile.create(
        name: 'Test User',
        height: 170.0,
        weight: 70.0,
        goal: 'maintain',
      );
      await StorageService.saveUserProfile(profile);
      await StorageService.setDarkMode(true);
      await StorageService.setOnboardingComplete(true);

      // Act
      await StorageService.clearAll();
      await StorageService.init();

      // Assert
      expect(StorageService.getUserProfile(), isNull);
      expect(StorageService.isDarkMode(), isFalse);
      expect(StorageService.isOnboardingComplete(), isFalse);
    });
  });
}
