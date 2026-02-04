// Validators
// Input validation utilities
import 'app_constants.dart';

class Validators {
  /// Validate email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.requiredField;
    }
    if (!ValidationPatterns.email.hasMatch(value)) {
      return ErrorMessages.invalidEmail;
    }
    return null;
  }

  /// Validate password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.requiredField;
    }
    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    if (!ValidationPatterns.password.hasMatch(value)) {
      return ErrorMessages.invalidPassword;
    }
    return null;
  }

  /// Validate confirm password
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.requiredField;
    }
    if (value != password) {
      return 'Mật khẩu không khớp';
    }
    return null;
  }

  /// Validate name
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.requiredField;
    }
    if (value.length < 2) {
      return 'Tên phải có ít nhất 2 ký tự';
    }
    if (value.length > 50) {
      return 'Tên không được quá 50 ký tự';
    }
    return null;
  }

  /// Validate required field
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return fieldName != null
          ? '$fieldName là bắt buộc'
          : ErrorMessages.requiredField;
    }
    return null;
  }

  /// Validate number
  static String? number(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.requiredField;
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Vui lòng nhập số hợp lệ';
    }
    if (min != null && number < min) {
      return 'Giá trị phải lớn hơn $min';
    }
    if (max != null && number > max) {
      return 'Giá trị phải nhỏ hơn $max';
    }
    return null;
  }

  /// Validate weight
  static String? weight(String? value) {
    return number(
      value,
      min: AppConstants.minWeight,
      max: AppConstants.maxWeight,
    );
  }

  /// Validate height
  static String? height(String? value) {
    return number(
      value,
      min: AppConstants.minHeight,
      max: AppConstants.maxHeight,
    );
  }

  /// Validate age
  static String? age(String? value) {
    return number(
      value,
      min: AppConstants.minAge.toDouble(),
      max: AppConstants.maxAge.toDouble(),
    );
  }

  /// Validate calories
  static String? calories(String? value) {
    return number(value, min: 0, max: AppConstants.maxCaloriesPerMeal);
  }

  /// Validate phone
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    if (!ValidationPatterns.phone.hasMatch(value)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  // Private constructor
  Validators._();
}

/// Sanitizers for input data
class Sanitizers {
  /// Remove extra whitespace
  static String trimAndNormalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Capitalize first letter
  static String capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  /// Capitalize each word
  static String capitalizeWords(String value) {
    return value.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Remove special characters
  static String removeSpecialChars(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  }

  /// Sanitize for database
  static String sanitizeForDb(String value) {
    return value.replaceAll("'", "''");
  }

  // Private constructor
  Sanitizers._();
}
