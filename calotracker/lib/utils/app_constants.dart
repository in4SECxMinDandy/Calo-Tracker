// App Constants
// All app-wide constants and configuration
class AppConstants {
  // App Info
  static const String appName = 'CaloTracker';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String appId = 'com.calotracker.calotracker';

  // URLs
  static const String privacyPolicyUrl = 'https://calotracker.app/privacy';
  static const String termsUrl = 'https://calotracker.app/terms';
  static const String supportEmail = 'support@calotracker.app';
  static const String websiteUrl = 'https://calotracker.app';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$appId';
  static const String appStoreUrl =
      'https://apps.apple.com/app/calotracker/id123456789';

  // API Configuration
  static const int apiTimeoutSeconds = 30;
  static const int maxRetries = 3;

  // Cache Configuration
  static const Duration cacheDuration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB

  // Nutrition Defaults
  static const double defaultCalorieTarget = 2000;
  static const double defaultProteinRatio = 0.25; // 25% of calories
  static const double defaultCarbsRatio = 0.50; // 50% of calories
  static const double defaultFatRatio = 0.25; // 25% of calories

  // Workout Defaults
  static const int workoutProgramWeeks = 12;
  static const int restDayOfWeek = 7; // Sunday
  static const int setsPerExercise = 3;

  // UI Constants
  static const double borderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 30.0;
  static const double iconSize = 24.0;
  static const double padding = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingLarge = 24.0;

  // Animation Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(milliseconds: 2500);
  static const Duration snackBarDuration = Duration(seconds: 3);

  // Limits
  static const int maxFoodNameLength = 100;
  static const int maxNoteLength = 500;
  static const int maxMealsPerDay = 20;
  static const double maxCaloriesPerMeal = 5000;
  static const double minWeight = 20;
  static const double maxWeight = 300;
  static const double minHeight = 100;
  static const double maxHeight = 250;
  static const int minAge = 10;
  static const int maxAge = 120;

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Storage Keys
  static const String keyDarkMode = 'dark_mode';
  static const String keyLanguage = 'language';
  static const String keyNotifications = 'notifications';
  static const String keyUserProfile = 'user_profile';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyLastSync = 'last_sync';
  static const String keyFirstLaunch = 'first_launch';

  // Feature Flags
  static const bool enableCloudSync = false;
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  static const bool enableAds = false;
  static const bool enablePremium = false;

  // Private constructor to prevent instantiation
  AppConstants._();
}

/// Validation patterns
class ValidationPatterns {
  static final RegExp email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp password = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$',
  );
  static final RegExp phone = RegExp(r'^[0-9]{10,11}$');
  static final RegExp name = RegExp(r'^[a-zA-ZÀ-ỹ\s]{2,50}$');

  ValidationPatterns._();
}

/// Error messages
class ErrorMessages {
  static const String networkError = 'Không có kết nối mạng';
  static const String serverError = 'Lỗi server, vui lòng thử lại';
  static const String unknownError = 'Đã có lỗi xảy ra';
  static const String authError = 'Lỗi xác thực';
  static const String invalidEmail = 'Email không hợp lệ';
  static const String invalidPassword =
      'Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ và số';
  static const String invalidName = 'Tên không hợp lệ';
  static const String requiredField = 'Trường này là bắt buộc';
  static const String invalidInput = 'Dữ liệu không hợp lệ';

  ErrorMessages._();
}
