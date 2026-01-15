import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Centralized app resources
///
/// This class provides common values used throughout the app:
/// - Dimensions (spacing, sizes, etc.)
/// - Durations (animations, delays, etc.)
/// - Other common constants
class AppResources {
  AppResources._(); // Private constructor to prevent instantiation

  // ==================== Dimensions ====================

  /// Standard spacing values
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  /// Border radius values
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;

  /// Icon sizes
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;

  /// Button heights
  static const double buttonHeightS = 40.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;

  /// Logo sizes
  static const double logoSizeSplash = 120.0;
  static const double logoSizeOnboarding = 80.0;
  static const double logoSizeAppBar = 32.0;

  // ==================== Durations ====================

  /// Animation durations
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationVerySlow = Duration(milliseconds: 800);

  /// Splash screen duration
  static const Duration splashScreenDuration = Duration(seconds: 3);

  /// Onboarding page transition duration
  static const Duration onboardingTransitionDuration = Duration(milliseconds: 400);

  // ==================== Opacity ====================

  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.60;
  static const double opacityHigh = 0.87;

  // ==================== Elevation ====================

  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
}

/// App-specific text styles
///
/// Extends the theme text styles with app-specific variations
class AppTextStyles {
  AppTextStyles._();

  /// Large title style (for onboarding headlines)
  static TextStyle largeTitle(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.headlineLarge?.copyWith(
          color: color ?? AppColors.brandPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ) ??
        const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.brandPrimary,
        );
  }

  /// Body text style for descriptions
  static TextStyle bodyDescription(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color ?? AppColors.textSecondary,
          fontSize: 16,
          height: 1.5,
        ) ??
        TextStyle(
          fontSize: 16,
          color: color ?? AppColors.textSecondary,
          height: 1.5,
        );
  }

  /// Button text style
  static TextStyle buttonText(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color ?? Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );
  }
}
