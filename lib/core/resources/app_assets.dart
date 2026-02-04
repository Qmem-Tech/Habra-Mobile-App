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

  /// Success icon for payment/order confirmation
  /// Expected path: assets/icons/success_icon.png
  static const String successIcon = '$_iconsPath/success_icon.png';

  // ==================== Home Feature Assets ====================
  /// Placeholder image for events
  /// Expected path: assets/images/home/event_placeholder.png
  static const String eventPlaceholder = '$_imagesPath/home/event_placeholder.png';

  /// Placeholder image for deals
  /// Expected path: assets/images/home/deal_placeholder.png
  static const String dealPlaceholder = '$_imagesPath/home/deal_placeholder.png';

  /// Placeholder image for businesses
  /// Expected path: assets/images/home/business_placeholder.png
  static const String businessPlaceholder = '$_imagesPath/home/business_placeholder.png';

  /// Placeholder image for jobs
  /// Expected path: assets/images/home/job_placeholder.png
  static const String jobPlaceholder = '$_imagesPath/home/job_placeholder.png';

  /// Empty state illustration for notifications
  /// Expected path: assets/images/home/notification_empty.png
  static const String notificationEmpty = '$_imagesPath/home/notification_empty.png';

  /// Empty state illustration for no results
  /// Expected path: assets/images/home/no_results.png
  static const String noResults = '$_imagesPath/home/no_results.png';

  // ==================== Business Owner Feature Assets ====================
  /// Business owner: placeholder for business cover/banner (use business_placeholder if no custom)
  static const String businessOwnerCoverPlaceholder = '$_imagesPath/home/business_placeholder.png';
  /// Business owner: placeholder for business logo
  static const String businessOwnerLogoPlaceholder = '$_imagesPath/home/business_placeholder.png';
  /// Business owner: new business / storefront illustration (add custom when provided)
  static const String businessOwnerNewBusiness = '$_imagesPath/home/business_placeholder.png';
  /// Business owner: new location / map pin illustration (add custom when provided)
  static const String businessOwnerNewLocation = '$_imagesPath/home/business_placeholder.png';
  /// Business owner: verification success / verified badge
  static const String businessOwnerVerifiedBadge = '$_iconsPath/success_icon.png';
  /// Business owner: camera/upload icon for Add Photos (use Material icon or add path when provided)
  /// Placeholder path for custom upload illustration
  static const String businessOwnerUploadPhoto = '$_imagesPath/home/business_placeholder.png';
  /// Business owner: pending review (document + clock). Replace with custom asset when provided.
  static const String businessOwnerPendingReview = '$_iconsPath/success_icon.png';

  // ==================== Jobs Feature Assets ====================
  /// Jobs folder base path
  static const String _jobsPath = '$_imagesPath/jobs';

  /// Cultural night hero image - Used for featured jobs, job cards, and general job illustrations
  /// Expected path: assets/images/jobs/cultural_night_hero.png
  static const String jobsCulturalNightHero = '$_jobsPath/cultural_night_hero.png';

  /// Cultural night image - Used for job listings, empty states, and general illustrations
  /// Expected path: assets/images/jobs/cultural_night.png
  static const String jobsCulturalNight = '$_jobsPath/cultural_night.png';

  /// Teddy afro concert image - Used for job cards, featured jobs, and illustrations
  /// Expected path: assets/images/jobs/teddy_afro_concert.png
  static const String jobsTeddyAfroConcert = '$_jobsPath/teddy_afro_concert.png';

  // Convenience aliases for specific use cases (can reuse the same images)
  /// Empty state illustration for no jobs found
  static const String noJobsFound = jobsCulturalNight;

  /// Empty state illustration for no applications
  static const String noApplications = jobsTeddyAfroConcert;

  /// Success icon/illustration for application submitted
  static const String applicationSubmitted = jobsCulturalNightHero;

  // ==================== Dashboard (Business Owner) Empty States ====================
  /// Empty state: no deals yet. Replace with custom asset when provided.
  static const String dashboardNoDeals = '$_imagesPath/home/no_results.png';
  /// Empty state: no job posts yet. Replace with custom asset when provided.
  static const String dashboardNoJobs = '$_imagesPath/home/no_results.png';
  /// Empty state: no analytics yet. Replace with custom asset when provided.
  static const String dashboardNoAnalytics = '$_imagesPath/home/no_results.png';
  /// Empty state: no reviews yet. Replace with custom asset when provided.
  static const String dashboardNoReviews = '$_imagesPath/home/no_results.png';
  /// Boost listing: rocket/visibility illustration. Replace with custom asset when provided.
  static const String dashboardBoostRocket = '$_imagesPath/home/business_placeholder.png';

  // ==================== Boosts Feature ====================
  /// Boosts empty state: no boosts used. Replace with custom asset when provided.
  static const String boostsEmptyState = '$_imagesPath/home/no_results.png';
  /// Boost order/payment success (gold checkmark). Use successIcon or replace when provided.
  static const String boostsOrderSuccess = '$_iconsPath/success_icon.png';
  /// Cancel boost modal: restaurant/listing image placeholder
  static const String boostsCancelListingPlaceholder = '$_imagesPath/home/business_placeholder.png';

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
      successIcon,
    ];
  }
}
