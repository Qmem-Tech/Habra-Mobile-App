import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

/// Central theme file for the app.
///
/// Exposes a single constant light theme. Use [AppTheme.theme] for MaterialApp.
/// Related: [AppColors], [AppFonts], [AppTextStyles] (in core/theme/).
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  /// The app's theme. Always light; no dark or system theme.
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        surface: AppColors.lightSurface,
        error: AppColors.lightError,
        onPrimary: AppColors.lightOnPrimary,
        onSecondary: AppColors.lightOnSecondary,
        onSurface: AppColors.lightOnSurface,
        onError: AppColors.lightOnError,
      ),
      textTheme: ThemeData.light().textTheme.merge(AppFonts.getTextTheme()),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.lightSurface,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
