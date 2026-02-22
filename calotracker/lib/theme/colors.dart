// Color scheme for CaloTracker app
// Supports both Light and Dark themes with iOS-style aesthetics
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Blue / Indigo for Calorie/BMR)
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueDark = Color(0xFF3B82F6);
  static const Color primaryIndigo = Color(0xFF6366F1); // New focus color

  // Success/Green (Weight Loss Goals)
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenLight = Color(0xFF34D399);

  // Warning/Error (Coral / Red)
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningCoral = Color(0xFFFF7F50); // New warning color
  static const Color errorRed = Color(0xFFEF4444);

  // Community Colors (Soft Orange / Teal)
  static const Color communityOrange = Color(0xFFFF8A65);
  static const Color communityTeal = Color(0xFF26A69A);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightDivider = Color(0xFFE5E7EB);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F0F23);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCardBackground = Color(0xFF1A1A2E);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkDivider = Color(0xFF374151);

  // Aliases for convenience (used in new screens)
  static const Color lightText = lightTextPrimary;
  static const Color darkText = darkTextPrimary;

  // Glass morphism colors
  static Color glassLight = Colors.white.withValues(alpha: 0.9);
  static Color glassDark = Colors.white.withValues(alpha: 0.1);
  static Color glassBorder = Colors.white.withValues(alpha: 0.2);

  // Gradient Colors for Cards
  static const List<Color> cameraCardGradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  static const List<Color> chatbotCardGradient = [
    Color(0xFF3B82F6),
    Color(0xFF2563EB),
  ];

  static const List<Color> gymCardGradient = [
    Color(0xFFF59E0B),
    Color(0xFFD97706),
  ];

  static const List<Color> healthyFoodCardGradient = [
    Color(0xFF4CAF50),
    Color(0xFF2E7D32),
  ];

  static const List<Color> exercisesCardGradient = [
    Color(0xFFE53935),
    Color(0xFFC62828),
  ];

  // Community Card Gradient (Soft Orange / Teal)
  static const List<Color> communityCardGradient = [
    Color(0xFFFF8A65), // Soft Orange
    Color(0xFF26A69A), // Teal
  ];

  // Chart Colors
  static const Color chartIntake = Color(0xFF10B981);
  static const Color chartBurned = Color(0xFFF59E0B);
  static const Color chartNet = Color(0xFF6366F1); // Indigo for focus

  // Additional Card/Surface Colors
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF1A1A2E);
}
