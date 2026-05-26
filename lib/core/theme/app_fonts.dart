import 'package:flutter/material.dart';

/// Central font configuration for the app
///
/// This class provides a single source of truth for all font families.
/// To change the app font, update the [fontFamily] constant below.
class AppFonts {
  AppFonts._(); // Private constructor to prevent instantiation

  // ==================== Font Family ====================
  /// Central font family for the entire app
  ///
  /// Change this value to update the font across the entire app.
  /// To use a custom font file:
  /// 1. Add font files to assets/fonts/
  /// 2. Declare them in pubspec.yaml
  /// 3. Set fontFamily to the family name from pubspec.yaml
  /// If null, uses the default system font
  static const String? fontFamily = null;

  // ==================== Text Theme Configuration ====================
  /// Get the primary text theme
  ///
  /// Returns Flutter's default text theme with optional custom font family
  static TextTheme getTextTheme() {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily),
      displayMedium: TextStyle(fontFamily: fontFamily),
      displaySmall: TextStyle(fontFamily: fontFamily),
      headlineLarge: TextStyle(fontFamily: fontFamily),
      headlineMedium: TextStyle(fontFamily: fontFamily),
      headlineSmall: TextStyle(fontFamily: fontFamily),
      titleLarge: TextStyle(fontFamily: fontFamily),
      titleMedium: TextStyle(fontFamily: fontFamily),
      titleSmall: TextStyle(fontFamily: fontFamily),
      bodyLarge: TextStyle(fontFamily: fontFamily),
      bodyMedium: TextStyle(fontFamily: fontFamily),
      bodySmall: TextStyle(fontFamily: fontFamily),
      labelLarge: TextStyle(fontFamily: fontFamily),
      labelMedium: TextStyle(fontFamily: fontFamily),
      labelSmall: TextStyle(fontFamily: fontFamily),
    );
  }

  /// Get a TextStyle with the app's font family
  ///
  /// Example usage:
  /// ```dart
  /// Text('Hello', style: AppFonts.getTextStyle(fontSize: 16))
  /// ```
  static TextStyle getTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontStyle: fontStyle,
    );
  }

  // ==================== Predefined Text Styles ====================

  /// Large title style (for onboarding, headers)
  static TextStyle largeTitle({Color? color}) {
    return getTextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: color,
      letterSpacing: -0.5,
    );
  }

  /// Medium title style
  static TextStyle mediumTitle({Color? color}) {
    return getTextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: -0.3,
    );
  }

  /// Body text style
  static TextStyle body({Color? color}) {
    return getTextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: color,
      height: 1.5,
    );
  }

  /// Body text style (small)
  static TextStyle bodySmall({Color? color}) {
    return getTextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: color,
      height: 1.4,
    );
  }

  /// Button text style
  static TextStyle button({Color? color}) {
    return getTextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.5,
    );
  }

  /// Caption text style
  static TextStyle caption({Color? color}) {
    return getTextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: color,
    );
  }
}
