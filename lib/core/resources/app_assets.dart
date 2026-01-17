/// Centralized asset management for the app
///
/// This class provides a single source of truth for all asset paths.
/// When assets are updated, only this file needs to be modified.
class AppAssets {
  AppAssets._(); // Private constructor to prevent instantiation

  // Base paths
  static const String _imagesPath = 'assets/images';
  static const String _iconsPath = 'assets/icons';
  static const String _logosPath = 'assets/logos';

  // ==================== Logos ====================
  /// App logo - Hexagonal logo with interconnected figures
  /// Expected path: assets/logos/habra_app_logo.png
  static const String appLogo = '$_logosPath/habra_app_logo.png';

  // ==================== Splash Screen ====================
  /// Splash screen logo (same as app logo, but may have different sizing)
  /// Expected path: assets/logos/habra_app_logo.png
  static const String splashLogo = '$_logosPath/habra_app_logo.png';

  // ==================== Onboarding Illustrations ====================
  /// Onboarding screen 1: "Discover Your Community" - Music Festival illustration
  /// Expected path: assets/images/onboarding/onboarding_screen_1.png
  static const String onboardingMusicFestival = '$_imagesPath/onboarding/onboarding_screen_1.png';

  /// Onboarding screen 2: "Support Local Businesses" - Coffee Shop illustration
  /// Expected path: assets/images/onboarding/onboarding_screen_2.png
  static const String onboardingCoffeeShop = '$_imagesPath/onboarding/onboarding_screen_2.png';

  /// Onboarding screen 3: "Grow Together" - Globe/Connectivity illustration
  /// Expected path: assets/images/onboarding/onboarding_screen_3.png
  static const String onboardingGrowTogether = '$_imagesPath/onboarding/onboarding_screen_3.png';

  // ==================== Icons ====================
  /// Close/Skip icon for onboarding
  /// Expected path: assets/icons/ic_close.png
  static const String icClose = '$_iconsPath/ic_close.png';

  // ==================== Helper Methods ====================
  /// Get asset path with optional fallback
  ///
  /// Example usage:
  /// ```dart
  /// AppAssets.getAsset(AppAssets.appLogo, fallback: 'assets/images/placeholder.png')
  /// ```
  static String getAsset(String assetPath, {String? fallback}) {
    return fallback ?? assetPath;
  }

  /// Validate that all required assets are present
  /// This can be used during development to check for missing assets
  static List<String> getRequiredAssets() {
    return [
      appLogo,
      splashLogo,
      onboardingMusicFestival,
      onboardingCoffeeShop,
      onboardingGrowTogether,
      icClose,
    ];
  }
}
