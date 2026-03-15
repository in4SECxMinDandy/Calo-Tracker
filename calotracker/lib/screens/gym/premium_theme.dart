import 'package:flutter/material.dart';

class PremiumTheme {
  // Colors
  static const Color background = Color(0xFF0F0F0F);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF2A2A2A);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textMuted = Color(0xFF666666);

  static const Color neonLime = Color(0xFFA3E635);
  static const Color electricBlue = Color(0xFF3B82F6);

  static const Color glassBorder = Color(0x33FFFFFF);

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 20.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 999.0;

  // Typography
  static const TextStyle headingLarge = TextStyle(
    fontFamily: 'SF Pro Display',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: 'SF Pro Display',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: 'SF Pro Display',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: textSecondary,
  );

  static const TextStyle dataDisplay = TextStyle(
    fontFamily: 'SF Pro Display',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonLime, Color(0xFF84cc16)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0x221A1A1A), Color(0x001A1A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> glowShadow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.3),
        blurRadius: 20,
        spreadRadius: 2,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> cardShadow() {
    return [
      BoxShadow(
        color: const Color(0xFF000000).withValues(alpha: 0.3),
        blurRadius: 20,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
