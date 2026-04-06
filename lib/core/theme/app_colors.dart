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
  static const Color brandPrimary = Color(0xFF1F563F); // Primary green

  /// Business owner home / marketing dashboard (matches owner-home mock).
  static const Color ownerHomePrimary = Color(0xFF1B4332);
  static const Color ownerHomeMintPill = Color(0xFFE8F5E9);

  /// Customer home (matches consumer home mock): location chip, key accents.
  static const Color customerHomePrimary = ownerHomePrimary;
  static const Color customerLocationPillBg = ownerHomeMintPill;
  /// Hot deal badge background (warm beige from mock).
  static const Color customerDealBadgeBg = Color(0xFFF5E6D3);
  static const Color ownerHomeSectionBg = Color(0xFFF8F9FA);
  static const Color ownerHomeQuickActionSecondary = Color(0xFFE8EAED);
  static const Color ownerOpenNowBadge = Color(0xFFD6C4A4);
  static const Color brandPrimaryLight = Color(0xFF2D6B4F);
  static const Color brandPrimaryDark = Color(0xFF16402F);

  /// Secondary brand color - Golden/tan (from design)
  /// Used for: Accents, secondary elements
  static const Color brandSecondary = Color(0xFFC1A25F); // Secondary gold/tan
  static const Color brandSecondaryLight = Color(0xFFD4B87A);
  static const Color brandSecondaryDark = Color(0xFFA88A4F);

  // ==================== Text Colors ====================
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ==================== Background Colors ====================
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundGrey = Color(0xFFE0E0E0);

  /// Settings / account screen: icon tile background (sage from design mock).
  static const Color settingsIconTileBackground = Color(0xFFD8E2DC);

  /// Log out and other destructive text accents (design mock).
  static const Color logoutActionText = Color(0xFFD9534F);

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
