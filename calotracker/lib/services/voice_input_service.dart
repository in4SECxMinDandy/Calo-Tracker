// Voice Input Service
// Speech-to-text functionality for hands-free food logging
// import 'package:speech_to_text/speech_to_text.dart';
// import 'package:speech_to_text/speech_recognition_result.dart';

class VoiceInputService {
  // static final SpeechToText _speechToText = SpeechToText();
  // Fields removed as part of stubbing
  // static bool _isInitialized = false;
  // static bool _isListening = false;
  // static String _currentLocale = 'vi_VN';

  /// Initialize speech recognition
  static Future<bool> init() async {
    return false;
  }

  /// Check if speech recognition is available
  static bool get isAvailable => false;

  /// Check if currently listening
  static bool get isListening => false;

  /// Get available locales
  static Future<List<dynamic>> getAvailableLocales() async {
    return [];
  }

  /// Set locale (language) for recognition
  static Future<void> setLocale(String localeId) async {
    // No-op
  }

  /// Start listening for speech input
  /// Returns a stream of recognition results
  static Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
  }) async {
    // Stub
  }

  /// Stop listening
  static Future<void> stopListening() async {}

  /// Cancel listening
  static Future<void> cancelListening() async {}

  /// Parse food input from speech text
  /// Extracts food name, quantity, and weight from natural language
  static FoodVoiceInput parseFoodInput(String text) {
    final lowerText = text.toLowerCase().trim();

    // Patterns for Vietnamese food input
    // Examples:
    // "một bát cơm" -> 1 bowl of rice
    // "200 gram thịt gà" -> 200g chicken
    // "hai quả trứng" -> 2 eggs
    // "một ly sữa" -> 1 glass of milk

    String? foodName;
    double? weight;
    int? quantity;
    String? unit;

    // Try to extract quantity and unit
    final quantityPatterns = [
      // Number + unit + food
      RegExp(
        r'(\d+(?:\.\d+)?)\s*(g|gram|gam|kg|ml|lít|lit|cốc|ly|bát|chén|đĩa|miếng|lát|quả|trái|củ|con)\s+(.+)',
        caseSensitive: false,
      ),
      // Vietnamese number words + unit + food
      RegExp(
        r'(một|hai|ba|bốn|năm|sáu|bảy|tám|chín|mười)\s+(cốc|ly|bát|chén|đĩa|miếng|lát|quả|trái|củ|con)\s+(.+)',
        caseSensitive: false,
      ),
      // Just number + food (assume grams)
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:g|gram|gam)?\s+(.+)', caseSensitive: false),
    ];

    for (final pattern in quantityPatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        if (match.groupCount >= 3) {
          // Has quantity/weight, unit, and food
          final numStr = match.group(1)!;
          unit = match.group(2);
          foodName = match.group(3)?.trim();

          // Convert to number
          if (RegExp(r'\d').hasMatch(numStr)) {
            final num = double.tryParse(numStr);
            if (unit != null && _isWeightUnit(unit)) {
              weight = _convertToGrams(num ?? 0, unit);
            } else {
              quantity = num?.toInt();
            }
          } else {
            quantity = _vietnameseToNumber(numStr);
          }
        } else if (match.groupCount >= 2) {
          // Just number and food
          final numStr = match.group(1)!;
          foodName = match.group(2)?.trim();
          weight = double.tryParse(numStr);
        }
        break;
      }
    }

    // If no pattern matched, use whole text as food name
    foodName ??= lowerText;

    // Clean up food name
    foodName = _cleanFoodName(foodName);

    return FoodVoiceInput(
      rawText: text,
      foodName: foodName,
      weight: weight,
      quantity: quantity,
      unit: unit,
    );
  }

  /// Parse workout input from speech
  static WorkoutVoiceInput parseWorkoutInput(String text) {
    final lowerText = text.toLowerCase().trim();

    String? workoutType;
    int? durationMinutes;

    // Patterns for workout input
    // "chạy bộ 30 phút"
    // "tập gym 1 tiếng"
    // "đạp xe nửa tiếng"

    // Extract duration
    final durationPatterns = [
      RegExp(r'(\d+)\s*(phút|phut)', caseSensitive: false),
      RegExp(r'(\d+)\s*(tiếng|tieng|giờ|gio)', caseSensitive: false),
      RegExp(r'(nửa|nua)\s*(tiếng|tieng|giờ|gio)', caseSensitive: false),
    ];

    for (final pattern in durationPatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        final numStr = match.group(1)!;
        final unit = match.group(2)!;

        if (numStr == 'nửa' || numStr == 'nua') {
          durationMinutes = 30;
        } else {
          final num = int.tryParse(numStr) ?? 0;
          if (unit.contains('tiếng') ||
              unit.contains('tieng') ||
              unit.contains('giờ') ||
              unit.contains('gio')) {
            durationMinutes = num * 60;
          } else {
            durationMinutes = num;
          }
        }

        // Remove duration from text to get workout type
        workoutType = lowerText.replaceAll(match.group(0)!, '').trim();
        break;
      }
    }

    workoutType ??= lowerText;

    // Map common Vietnamese workout names
    workoutType = _normalizeWorkoutType(workoutType);

    return WorkoutVoiceInput(
      rawText: text,
      workoutType: workoutType,
      durationMinutes: durationMinutes,
    );
  }

  // ==================== PRIVATE METHODS ====================

  // Private methods removed due to plugin fix
  /*
  static void _onSpeechResult(
    dynamic result,
    Function(String text, bool isFinal) onResult,
  ) {
    // onResult(result.recognizedWords, result.finalResult);
  }
  */

  static bool _isWeightUnit(String unit) {
    return [
      'g',
      'gram',
      'gam',
      'kg',
      'ml',
      'lít',
      'lit',
    ].contains(unit.toLowerCase());
  }

  static double _convertToGrams(double value, String unit) {
    switch (unit.toLowerCase()) {
      case 'kg':
        return value * 1000;
      case 'ml':
      case 'lít':
      case 'lit':
        return value; // Approximate 1ml = 1g for liquids
      default:
        return value;
    }
  }

  static int _vietnameseToNumber(String word) {
    const map = {
      'một': 1,
      'hai': 2,
      'ba': 3,
      'bốn': 4,
      'năm': 5,
      'sáu': 6,
      'bảy': 7,
      'tám': 8,
      'chín': 9,
      'mười': 10,
    };
    return map[word.toLowerCase()] ?? 1;
  }

  static String _cleanFoodName(String name) {
    // Remove common filler words
    final fillers = ['ăn', 'uống', 'một', 'cái', 'con', 'của'];
    var cleaned = name;
    for (final filler in fillers) {
      cleaned = cleaned.replaceAll(
        RegExp('^$filler\\s+', caseSensitive: false),
        '',
      );
    }
    return cleaned.trim();
  }

  static String _normalizeWorkoutType(String type) {
    final mappings = {
      'chạy bộ': 'Chạy bộ',
      'chay bo': 'Chạy bộ',
      'đi bộ': 'Đi bộ',
      'di bo': 'Đi bộ',
      'gym': 'Tập Gym',
      'tập gym': 'Tập Gym',
      'đạp xe': 'Đạp xe',
      'dap xe': 'Đạp xe',
      'bơi': 'Bơi lội',
      'bơi lội': 'Bơi lội',
      'yoga': 'Yoga',
      'aerobic': 'Aerobic',
      'nhảy dây': 'Nhảy dây',
      'plank': 'Plank',
      'squat': 'Squat',
      'cardio': 'Cardio',
    };

    for (final entry in mappings.entries) {
      if (type.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }

    // Capitalize first letter
    if (type.isNotEmpty) {
      return type[0].toUpperCase() + type.substring(1);
    }
    return type;
  }
}

/// Result of parsing food voice input
class FoodVoiceInput {
  final String rawText;
  final String foodName;
  final double? weight; // grams
  final int? quantity;
  final String? unit;

  FoodVoiceInput({
    required this.rawText,
    required this.foodName,
    this.weight,
    this.quantity,
    this.unit,
  });

  /// Get display string for the parsed input
  String get displayText {
    final parts = <String>[];
    if (quantity != null) {
      parts.add('$quantity');
      if (unit != null) parts.add(unit!);
    }
    if (weight != null) {
      parts.add('${weight!.toInt()}g');
    }
    parts.add(foodName);
    return parts.join(' ');
  }

  /// Check if parsing was successful
  bool get isValid => foodName.isNotEmpty;

  @override
  String toString() =>
      'FoodVoiceInput(food: $foodName, weight: $weight, qty: $quantity)';
}

/// Result of parsing workout voice input
class WorkoutVoiceInput {
  final String rawText;
  final String workoutType;
  final int? durationMinutes;

  WorkoutVoiceInput({
    required this.rawText,
    required this.workoutType,
    this.durationMinutes,
  });

  /// Get display string
  String get displayText {
    if (durationMinutes != null) {
      if (durationMinutes! >= 60) {
        final hours = durationMinutes! ~/ 60;
        final mins = durationMinutes! % 60;
        if (mins > 0) {
          return '$workoutType - ${hours}h${mins}m';
        }
        return '$workoutType - $hours tiếng';
      }
      return '$workoutType - $durationMinutes phút';
    }
    return workoutType;
  }

  bool get isValid => workoutType.isNotEmpty;

  @override
  String toString() =>
      'WorkoutVoiceInput(type: $workoutType, duration: $durationMinutes)';
}

/// Voice input exception
class VoiceInputException implements Exception {
  final String message;
  VoiceInputException(this.message);

  @override
  String toString() => 'VoiceInputException: $message';
}
