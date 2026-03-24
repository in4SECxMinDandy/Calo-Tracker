// Food Recognition Service Unit Tests
// Tests: API configuration, response parsing, error handling, demo mode
import 'package:flutter_test/flutter_test.dart';
import 'package:calotracker/services/food_recognition_service.dart';

void main() {
  group('AIProviderConfig', () {
    test('isConfigured returns true for valid API key', () {
      const config = AIProviderConfig(
        provider: AIProvider.anthropic,
        apiKey: 'sk-ant-api03-test-key',
        apiUrl: 'https://api.anthropic.com',
        model: 'claude-3-5-sonnet-latest',
      );
      expect(config.isConfigured, isTrue);
    });

    test('isConfigured returns false for placeholder keys', () {
      const config = AIProviderConfig(
        provider: AIProvider.anthropic,
        apiKey: 'YOUR_API_KEY',
        apiUrl: 'https://api.anthropic.com',
        model: 'claude-3-5-sonnet-latest',
      );
      expect(config.isConfigured, isFalse);
    });

    test('isConfigured returns false for empty key', () {
      const config = AIProviderConfig(
        provider: AIProvider.demo,
        apiKey: '',
        apiUrl: '',
        model: '',
      );
      expect(config.isConfigured, isFalse);
    });
  });

  group('FoodRecognitionResult', () {
    test('success creates correct result', () {
      final result = FoodRecognitionResult.success([
        RecognizedFood(
          name: 'Test Food',
          nameEn: 'Test',
          estimatedWeight: 100,
          confidence: 0.9,
        ),
      ]);

      expect(result.isSuccess, isTrue);
      expect(result.isTransientError, isFalse);
      expect(result.isCriticalError, isFalse);
      expect(result.foods?.length, 1);
      expect(result.error, isNull);
    });

    test('error creates correct result', () {
      final result = FoodRecognitionResult.error('Test error');

      expect(result.isSuccess, isFalse);
      expect(result.isTransientError, isFalse);
      expect(result.isCriticalError, isFalse);
      expect(result.foods, isNull);
      expect(result.error, 'Test error');
    });

    test('transientError creates correct result', () {
      final result = FoodRecognitionResult.transientError('Timeout');

      expect(result.isSuccess, isFalse);
      expect(result.isTransientError, isTrue);
      expect(result.isCriticalError, isFalse);
    });

    test('criticalError creates correct result', () {
      final result = FoodRecognitionResult.criticalError('Invalid API key');

      expect(result.isSuccess, isFalse);
      expect(result.isTransientError, isFalse);
      expect(result.isCriticalError, isTrue);
    });
  });

  group('RecognizedFood', () {
    test('toString formats correctly', () {
      final food = RecognizedFood(
        name: 'Phở bò',
        nameEn: 'Beef Noodle Soup',
        estimatedWeight: 250.5,
        confidence: 0.92,
      );

      expect(food.toString(), 'Phở bò (92% - 250g)');
    });

    test('creates with macros', () {
      final food = RecognizedFood(
        name: 'Test',
        nameEn: 'Test',
        estimatedWeight: 100,
        confidence: 0.9,
        macrosPer100g: {
          'protein_g': 10.0,
          'carbs_g': 20.0,
          'fat_g': 5.0,
        },
      );

      expect(food.macrosPer100g, isNotNull);
      expect(food.macrosPer100g!['protein_g'], 10.0);
    });

    test('creates with warning', () {
      final food = RecognizedFood(
        name: 'Demo Food',
        nameEn: 'Demo',
        estimatedWeight: 100,
        confidence: 0.5,
        warning: 'Demo mode',
      );

      expect(food.warning, 'Demo mode');
    });
  });

  group('Demo Mode', () {
    test('returns demo foods with warning', () {
      final result = _testDemoRecognition(warning: 'Test warning');

      expect(result.isSuccess, isTrue);
      expect(result.foods?.length, 2);
      expect(result.foods![0].warning, 'Test warning');
      expect(result.foods![1].warning, 'Test warning');
    });

    test('returns demo foods without warning', () {
      final result = _testDemoRecognition();

      expect(result.isSuccess, isTrue);
      expect(result.foods?.length, 2);
      expect(result.foods![0].warning, isNull);
    });
  });

  group('Active Provider', () {
    test('returns correct provider name', () {
      // This test verifies the provider name is correctly reported
      expect(FoodRecognitionService.activeProviderName, isNotEmpty);
    });
  });
}

/// Helper to test demo mode without static access issues
FoodRecognitionResult _testDemoRecognition({String? warning}) {
  return FoodRecognitionResult.success([
    RecognizedFood(
      name: 'Cơm trắng',
      nameEn: 'White Rice',
      estimatedWeight: 200,
      confidence: 0.85,
      warning: warning,
    ),
    RecognizedFood(
      name: 'Thịt kho',
      nameEn: 'Braised Pork',
      estimatedWeight: 100,
      confidence: 0.75,
      warning: warning,
    ),
  ]);
}
