// Analytics Service - Firebase Analytics
// Tracks user events and screen views
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Analytics Event Types
class AnalyticsEvents {
  static const String screenView = 'screen_view';
  static const String mealAdded = 'meal_added';
  static const String photoScanned = 'photo_scanned';
  static const String workoutStarted = 'workout_started';
  static const String workoutCompleted = 'workout_completed';
  static const String exerciseViewed = 'exercise_viewed';
  static const String videoWatched = 'video_watched';
  static const String settingsChanged = 'settings_changed';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String appOpened = 'app_opened';
  static const String signIn = 'sign_in';
  static const String signOut = 'sign_out';
}

/// Analytics Service
/// Note: Full implementation requires firebase_analytics package
class AnalyticsService {
  static bool _isInitialized = false;
  static final List<Map<String, dynamic>> _eventQueue = [];

  /// Initialize analytics
  static Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // In production:
    // await Firebase.initializeApp();
    // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

    // Process queued events
    for (final event in _eventQueue) {
      await _logEvent(event['name'], event['parameters']);
    }
    _eventQueue.clear();
  }

  /// Log a custom event
  static Future<void> logEvent(
    String name, [
    Map<String, dynamic>? parameters,
  ]) async {
    if (!_isInitialized) {
      _eventQueue.add({'name': name, 'parameters': parameters});
      return;
    }
    await _logEvent(name, parameters);
  }

  static Future<void> _logEvent(
    String name,
    Map<String, dynamic>? parameters,
  ) async {
    // In production:
    // await FirebaseAnalytics.instance.logEvent(
    //   name: name,
    //   parameters: parameters,
    // );

    // Debug logging
    debugPrint('[Analytics] Event: $name, Params: $parameters');
  }

  /// Log screen view
  static Future<void> logScreenView(String screenName) async {
    await logEvent(AnalyticsEvents.screenView, {
      'screen_name': screenName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log meal added
  static Future<void> logMealAdded({
    required String foodName,
    required double calories,
    required String source,
  }) async {
    await logEvent(AnalyticsEvents.mealAdded, {
      'food_name': foodName,
      'calories': calories,
      'source': source,
    });
  }

  /// Log photo scanned
  static Future<void> logPhotoScanned({
    required bool success,
    required int foodsDetected,
  }) async {
    await logEvent(AnalyticsEvents.photoScanned, {
      'success': success,
      'foods_detected': foodsDetected,
    });
  }

  /// Log workout started
  static Future<void> logWorkoutStarted({
    required String workoutId,
    required int exerciseCount,
  }) async {
    await logEvent(AnalyticsEvents.workoutStarted, {
      'workout_id': workoutId,
      'exercise_count': exerciseCount,
    });
  }

  /// Log workout completed
  static Future<void> logWorkoutCompleted({
    required String workoutId,
    required int durationMinutes,
    required int caloriesBurned,
  }) async {
    await logEvent(AnalyticsEvents.workoutCompleted, {
      'workout_id': workoutId,
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
    });
  }

  /// Log exercise viewed
  static Future<void> logExerciseViewed(String exerciseId) async {
    await logEvent(AnalyticsEvents.exerciseViewed, {'exercise_id': exerciseId});
  }

  /// Log video watched
  static Future<void> logVideoWatched({
    required String exerciseId,
    required String videoUrl,
  }) async {
    await logEvent(AnalyticsEvents.videoWatched, {
      'exercise_id': exerciseId,
      'video_url': videoUrl,
    });
  }

  /// Log settings changed
  static Future<void> logSettingsChanged(String setting, dynamic value) async {
    await logEvent(AnalyticsEvents.settingsChanged, {
      'setting': setting,
      'value': value.toString(),
    });
  }

  /// Log onboarding completed
  static Future<void> logOnboardingCompleted({
    required String goal,
    required double height,
    required double weight,
  }) async {
    await logEvent(AnalyticsEvents.onboardingCompleted, {
      'goal': goal,
      'height': height,
      'weight': weight,
    });
  }

  /// Log app opened
  static Future<void> logAppOpened() async {
    await logEvent(AnalyticsEvents.appOpened, {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Set user properties
  static Future<void> setUserProperties({
    String? userId,
    String? userType,
    String? goal,
  }) async {
    // In production:
    // if (userId != null) {
    //   await FirebaseAnalytics.instance.setUserId(id: userId);
    // }
    // await FirebaseAnalytics.instance.setUserProperty(name: 'user_type', value: userType);
    // await FirebaseAnalytics.instance.setUserProperty(name: 'goal', value: goal);

    debugPrint(
      '[Analytics] Set user properties: userId=$userId, type=$userType, goal=$goal',
    );
  }

  /// Reset analytics data
  static Future<void> resetAnalyticsData() async {
    // In production:
    // await FirebaseAnalytics.instance.resetAnalyticsData();
    debugPrint('[Analytics] Reset analytics data');
  }
}
