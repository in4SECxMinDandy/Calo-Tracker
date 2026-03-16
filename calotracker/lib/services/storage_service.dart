// Storage Service
// SharedPreferences for user settings and app state
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/sleep_signal_event.dart';

class StorageService {
  static SharedPreferences? _prefs;

  // Keys
  static const String _keyUser = 'user_profile';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyLanguage = 'language';
  static const String _keyCountry = 'country';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyOnlineMode = 'online_mode';
  static const String _keyHasSeenWelcome = 'has_seen_welcome';

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== USER PROFILE ====================

  /// Save user profile
  static Future<bool> saveUserProfile(UserProfile profile) async {
    final json = jsonEncode(profile.toMap());
    return await prefs.setString(_keyUser, json);
  }

  /// Get user profile
  static UserProfile? getUserProfile() {
    final json = prefs.getString(_keyUser);
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return UserProfile.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  /// Check if user profile exists
  static bool hasUserProfile() {
    return prefs.containsKey(_keyUser);
  }

  /// Delete user profile
  static Future<bool> deleteUserProfile() async {
    return await prefs.remove(_keyUser);
  }

  // ==================== ONBOARDING ====================

  /// Set onboarding complete
  static Future<bool> setOnboardingComplete(bool complete) async {
    return await prefs.setBool(_keyOnboardingComplete, complete);
  }

  /// Check if onboarding is complete
  static bool isOnboardingComplete() {
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  // ==================== THEME ====================

  /// Set dark mode preference
  static Future<bool> setDarkMode(bool enabled) async {
    return await prefs.setBool(_keyDarkMode, enabled);
  }

  /// Get dark mode preference
  static bool isDarkMode() {
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  // ==================== LANGUAGE ====================

  /// Set language
  static Future<bool> setLanguage(String languageCode) async {
    return await prefs.setString(_keyLanguage, languageCode);
  }

  /// Get language (default: Vietnamese)
  static String getLanguage() {
    return prefs.getString(_keyLanguage) ?? 'vi';
  }

  /// Get supported languages
  static List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
    ];
  }

  // ==================== COUNTRY ====================

  /// Set country
  static Future<bool> setCountry(String countryCode) async {
    return await prefs.setString(_keyCountry, countryCode);
  }

  /// Get country (default: Vietnam)
  static String getCountry() {
    return prefs.getString(_keyCountry) ?? 'VN';
  }

  /// Get supported countries
  static List<Map<String, String>> getSupportedCountries() {
    return [
      {'code': 'VN', 'name': 'Việt Nam', 'flag': '🇻🇳'},
      {'code': 'US', 'name': 'United States', 'flag': '🇺🇸'},
      {'code': 'JP', 'name': 'Japan', 'flag': '🇯🇵'},
      {'code': 'KR', 'name': 'South Korea', 'flag': '🇰🇷'},
      {'code': 'TH', 'name': 'Thailand', 'flag': '🇹🇭'},
      {'code': 'CN', 'name': 'China', 'flag': '🇨🇳'},
      {'code': 'IN', 'name': 'India', 'flag': '🇮🇳'},
      {'code': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧'},
      {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪'},
      {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
      {'code': 'AU', 'name': 'Australia', 'flag': '🇦🇺'},
      {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
    ];
  }

  // ==================== NOTIFICATIONS ====================

  /// Set notifications enabled
  static Future<bool> setNotificationsEnabled(bool enabled) async {
    return await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  /// Check if notifications are enabled
  static bool isNotificationsEnabled() {
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  // ==================== BIOMETRICS ====================

  /// Enable/disable biometric auth
  static Future<bool> setBiometricEnabled(bool enabled) async {
    return await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  /// Check if biometric auth is enabled
  static bool isBiometricEnabled() {
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  // ==================== UTILITY ====================

  /// Clear all preferences
  static Future<bool> clearAll() async {
    return await prefs.clear();
  }

  // ==================== ONLINE MODE ====================

  /// Set online mode preference
  static Future<bool> setOnlineMode(bool enabled) async {
    return await prefs.setBool(_keyOnlineMode, enabled);
  }

  /// Check if online mode is enabled
  static bool isOnlineMode() {
    return prefs.getBool(_keyOnlineMode) ?? false;
  }

  // ==================== WELCOME SCREEN ====================

  /// Set has seen welcome screen
  static Future<bool> setHasSeenWelcome(bool seen) async {
    return await prefs.setBool(_keyHasSeenWelcome, seen);
  }

  /// Check if user has seen welcome screen
  static bool hasSeenWelcome() {
    return prefs.getBool(_keyHasSeenWelcome) ?? false;
  }

  // ==================== PASSIVE SLEEP TRACKING ====================

  // Keys
  static const String _keyPassiveSleepEnabled = 'passive_sleep_enabled';
  static const String _keySleepSignalEvents = 'sleep_signal_events';
  static const String _keySleepSessions = 'sleep_sessions';

  /// Enable/disable passive sleep tracking
  static Future<bool> setPassiveSleepEnabled(bool enabled) async {
    return await prefs.setBool(_keyPassiveSleepEnabled, enabled);
  }

  /// Check if passive sleep tracking is enabled
  static bool isPassiveSleepEnabled() {
    return prefs.getBool(_keyPassiveSleepEnabled) ?? false;
  }

  /// Save sleep signal events (batch) - accepts SleepSignalEvent objects
  static Future<bool> saveSleepSignalEvents(List<SleepSignalEvent> events) async {
    final eventsMap = events.map((e) => e.toMap()).toList();
    final json = jsonEncode(eventsMap);
    return await prefs.setString(_keySleepSignalEvents, json);
  }

  /// Save sleep signal events (batch) - accepts List of Map
  static Future<bool> saveSleepSignalEventsRaw(List<Map<String, dynamic>> events) async {
    final json = jsonEncode(events);
    return await prefs.setString(_keySleepSignalEvents, json);
  }

  /// Get sleep signal events
  static List<Map<String, dynamic>> getSleepSignalEvents() {
    final json = prefs.getString(_keySleepSignalEvents);
    if (json == null) return [];

    try {
      final list = jsonDecode(json) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Save sleep sessions
  static Future<bool> saveSleepSessions(List<Map<String, dynamic>> sessions) async {
    final json = jsonEncode(sessions);
    return await prefs.setString(_keySleepSessions, json);
  }

  /// Get sleep sessions
  static List<Map<String, dynamic>> getSleepSessions() {
    final json = prefs.getString(_keySleepSessions);
    if (json == null) return [];

    try {
      final list = jsonDecode(json) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Delete all sleep data
  static Future<bool> deleteAllSleepData() async {
    await prefs.remove(_keySleepSignalEvents);
    await prefs.remove(_keySleepSessions);
    return true;
  }
}
