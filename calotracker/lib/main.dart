// CaloTracker - iOS-style Nutrition & Health Tracking App
// Main entry point with theme and navigation setup
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'l10n/app_localizations.dart';

import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'core/config/supabase_config.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Critical services only - must be ready before UI
  await StorageService.init();

  // Initialize date formatting for Vietnamese
  await initializeDateFormatting('vi', null);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run app immediately - defer heavy init to avoid skipped frames
  runApp(const CaloTrackerApp());

  // Defer non-critical initialization to after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await NotificationService.init();
    await AnalyticsService.init();
    await AuthService.init();

    // Initialize Supabase (optional - won't fail if not configured)
    try {
      await SupabaseConfig.initialize();
    } catch (e) {
      debugPrint('Supabase not configured: $e');
    }

    await AnalyticsService.logAppOpened();
  });
}

class CaloTrackerApp extends StatefulWidget {
  const CaloTrackerApp({super.key});

  @override
  State<CaloTrackerApp> createState() => _CaloTrackerAppState();

  /// Allows rebuilding the app from anywhere (for theme/language changes)
  static void rebuild(BuildContext context) {
    context.findAncestorStateOfType<_CaloTrackerAppState>()?.rebuild();
  }
}

class _CaloTrackerAppState extends State<CaloTrackerApp> {
  bool _isDarkMode = false;
  String _language = 'vi';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _isDarkMode = StorageService.isDarkMode();
    _language = StorageService.getLanguage();
  }

  void rebuild() {
    setState(() {
      _loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaloTracker',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(_language),

      // Home
      home: const AppInitializer(),
      routes: {'/login': (context) => const LoginScreen()},
    );
  }
}

/// Initializes app and decides which screen to show
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  Widget build(BuildContext context) {
    // Always show splash screen first - it handles navigation
    return const SplashScreen();
  }
}
