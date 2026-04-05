/// Centralized asset management for the app
///
/// Paths match the committed `assets/` tree (see repo `assets/` folders).
/// When you add files, register the folder in [pubspec.yaml] and add constants here.
class AppAssets {
  AppAssets._();

  static const String _imagesPath = 'assets/images';
  static const String _iconsPath = 'assets/icons';
  static const String _logosPath = 'assets/logos';
  static const String _illustrationPath = 'assets/illustration';

  // --- Files that exist under assets/images/home/ ---
  static const String _homeNoResults = '$_imagesPath/home/no_results.png';
  static const String _homeNotificationEmpty = '$_imagesPath/home/notification_empty.png';

  // --- Illustration PNGs ---
  static const String _illustrationMailbox = '$_illustrationPath/mailbox.png';

  // ==================== Logos ====================
  static const String appLogo = '$_logosPath/habra_app_logo.png';
  static const String splashLogo = '$_logosPath/habra_app_logo.png';

  // ==================== Onboarding ====================
  static const String onboardingMusicFestival = '$_imagesPath/onboarding/onboarding_screen_1.png';
  static const String onboardingCoffeeShop = '$_imagesPath/onboarding/onboarding_screen_2.png';
  static const String onboardingGrowTogether = '$_imagesPath/onboarding/onboarding_screen_3.png';

  // ==================== Icons ====================
  /// No `ic_close.png` in repo; onboarding uses [Icons.close]. Kept for callers that expect a path.
  static const String icClose = '$_iconsPath/success_icon.png';

  static const String successIcon = '$_iconsPath/success_icon.png';

  // ==================== Home / list placeholders ====================
  /// Generic card placeholder (no dedicated asset — reuse empty-state art).
  static const String eventPlaceholder = _homeNoResults;
  static const String dealPlaceholder = _homeNoResults;
  static const String businessPlaceholder = _homeNoResults;
  static const String jobPlaceholder = _homeNoResults;

  static const String notificationEmpty = _homeNotificationEmpty;
  static const String noResults = _homeNoResults;

  // ==================== Business owner ====================
  static const String businessOwnerCoverPlaceholder = _homeNoResults;
  static const String businessOwnerLogoPlaceholder = _homeNoResults;
  static const String businessOwnerNewBusiness = _illustrationMailbox;
  static const String businessOwnerNewLocation = _homeNoResults;
  static const String businessOwnerVerifiedBadge = successIcon;
  static const String businessOwnerUploadPhoto = _homeNoResults;
  static const String businessOwnerPendingReview = successIcon;

  // ==================== Jobs ====================
  static const String jobsCulturalNightHero = _homeNoResults;
  static const String jobsCulturalNight = _homeNoResults;
  static const String jobsTeddyAfroConcert = _homeNoResults;
  static const String noJobsFound = jobsCulturalNight;
  static const String noApplications = jobsTeddyAfroConcert;
  static const String applicationSubmitted = jobsCulturalNightHero;

  // ==================== Dashboard ====================
  static const String dashboardNoDeals = _homeNoResults;
  static const String dashboardNoJobs = _homeNoResults;
  static const String dashboardNoAnalytics = _homeNoResults;
  static const String dashboardNoReviews = _homeNoResults;
  static const String dashboardBoostRocket = _homeNoResults;
  static const String rocketLaunchSvg = '$_illustrationPath/rocket_launch.svg';
  static const String pendingStatusSvg = '$_illustrationPath/pending_status.svg';

  // ==================== Community ====================
  static const String savedItemsEmpty = _homeNoResults;
  static const String myReviewsEmpty = _homeNoResults;

  // ==================== Boosts ====================
  static const String boostsEmptyState = _homeNoResults;
  static const String boostsOrderSuccess = successIcon;
  static const String boostsCancelListingPlaceholder = _homeNoResults;

  static String getAsset(String assetPath, {String? fallback}) {
    return fallback ?? assetPath;
  }

  static List<String> getRequiredAssets() {
    return [
      appLogo,
      splashLogo,
      onboardingMusicFestival,
      onboardingCoffeeShop,
      onboardingGrowTogether,
      successIcon,
      _homeNoResults,
      _homeNotificationEmpty,
      _illustrationMailbox,
      rocketLaunchSvg,
      pendingStatusSvg,
    ];
  }
}
