// Supabase Configuration
// Centralized configuration for Supabase connection
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ✅ URL chính xác (lưu ý đuôi .co không phải .com)
  static const String supabaseUrl = 'https://uwoalhebpdxqptoxonxt.supabase.co';

  // ✅ Supabase Anon Public Key (JWT format)
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV3b2FsaGVicGR4cXB0b3hvbnh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk5Mjg0MjUsImV4cCI6MjA4NTUwNDQyNX0.6hevJ2C9G4IbylloJgpa6hk4mpOvhoUcReELUbV-rmg';

  // 🤖 Gemini API Key (Google AI Studio - https://aistudio.google.com/app/apikey)
  // Thay thế bằng API key thực của bạn để kích hoạt AI dinh dưỡng
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';

  // Track if Supabase has been successfully initialized
  static bool _isInitialized = false;

  // Check if Supabase is configured (credentials are set)
  static bool get isConfigured =>
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
      supabaseAnonKey.startsWith('eyJ');

  // Check if Supabase is ready to use
  static bool get isInitialized => _isInitialized;

  // Initialize Supabase
  static Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint(
        '⚠️ Supabase not configured. Community features will be disabled.',
      );
      _isInitialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );
      _isInitialized = true;
      debugPrint('✅ Supabase initialized successfully');
    } catch (e) {
      _isInitialized = false;
      debugPrint('❌ Failed to initialize Supabase: $e');
    }
  }

  // Get Supabase client (returns null if not initialized)
  static SupabaseClient? get clientOrNull {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (e) {
      return null;
    }
  }

  // Get Supabase client (throws if not initialized - use with caution)
  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        'Supabase is not initialized. Please configure your credentials in supabase_config.dart',
      );
    }
    return Supabase.instance.client;
  }

  // Get current user (returns null if not initialized or not authenticated)
  static User? get currentUser {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  // Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  // Get current session (returns null if not initialized)
  static Session? get currentSession {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client.auth.currentSession;
    } catch (e) {
      return null;
    }
  }
}
