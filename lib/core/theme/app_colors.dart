import 'package:flutter/material.dart';

/// App color constants
///
/// This class defines all colors used throughout the app.
/// Based on the Habra brand design with dark green as primary color.
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ==================== Brand Colors ====================
  /// Primary brand color - Dark green (from design)
  /// Used for: Primary buttons, active states, progress indicators
  static const Color brandPrimary = Color(0xFF1B5E20); // Dark forest green
  static const Color brandPrimaryLight = Color(0xFF2E7D32);
  static const Color brandPrimaryDark = Color(0xFF0D3E10);

  /// Secondary brand color - Golden brown/tan (from logo)
  /// Used for: Accents, secondary elements
  static const Color brandSecondary = Color(0xFFD4A574); // Golden brown/tan
  static const Color brandSecondaryLight = Color(0xFFE8C19A);
  static const Color brandSecondaryDark = Color(0xFFB8904F);

  // ==================== Text Colors ====================
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ==================== Background Colors ====================
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundGrey = Color(0xFFE0E0E0);

  // ==================== Light Theme Colors ====================
  static const Color lightPrimary = brandPrimary;
  static const Color lightSecondary = brandSecondary;
  static const Color lightBackground = backgroundWhite;
  static const Color lightSurface = backgroundWhite;
  static const Color lightError = Color(0xFFB00020);
  static const Color lightOnPrimary = textOnPrimary;
  static const Color lightOnSecondary = textPrimary;
  static const Color lightOnBackground = textPrimary;
  static const Color lightOnSurface = textPrimary;
  static const Color lightOnError = textOnPrimary;

  // ==================== Dark Theme Colors ====================
  static const Color darkPrimary = Color(0xFF4CAF50); // Lighter green for dark theme
  static const Color darkSecondary = brandSecondary;
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkError = Color(0xFFCF6679);
  static const Color darkOnPrimary = textPrimary;
  static const Color darkOnSecondary = textPrimary;
  static const Color darkOnBackground = textOnPrimary;
  static const Color darkOnSurface = textOnPrimary;
  static const Color darkOnError = textPrimary;

  // ==================== Status Colors ====================
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFB00020);
  static const Color info = Color(0xFF2196F3);

  // ==================== Progress Indicator ====================
  /// Active progress indicator color (dark green)
  static const Color progressActive = brandPrimary;
  /// Inactive progress indicator color (light grey)
  static const Color progressInactive = Color(0xFFE0E0E0);
}
