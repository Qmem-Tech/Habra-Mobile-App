import 'app_config.dart';

/// Feature flags for business-owner paid tools (Dashboard, Boosts).
///
/// Set via `--dart-define=BUSINESS_OWNER_SUBSCRIPTION_MODE=...` ([AppConfig]).
///
/// - **off** (default): No subscription gate (previous behavior).
/// - **revenuecat**: Gate on RevenueCat entitlement [revenueCatEntitlementId].
/// - **profile**: Gate on `profiles.owner_tools_subscription_active` (nullable column;
///   missing column or fetch error → treat as **active** so unmigrated backends keep working).
/// - **stub_locked**: Always locked (QA / UI testing).
enum BusinessOwnerSubscriptionMode {
  off,
  revenuecat,
  profile,
  stubLocked,
}

class BusinessSubscriptionConfig {
  BusinessSubscriptionConfig._();

  static BusinessOwnerSubscriptionMode get mode {
    final raw = AppConfig.businessOwnerSubscriptionMode;
    switch (raw) {
      case 'revenuecat':
        return BusinessOwnerSubscriptionMode.revenuecat;
      case 'profile':
        return BusinessOwnerSubscriptionMode.profile;
      case 'stub_locked':
        return BusinessOwnerSubscriptionMode.stubLocked;
      default:
        return BusinessOwnerSubscriptionMode.off;
    }
  }

  /// RevenueCat entitlement identifier when mode is [BusinessOwnerSubscriptionMode.revenuecat].
  static String get revenueCatEntitlementId =>
      AppConfig.revenueCatBusinessEntitlementId;

  /// RevenueCat offering identifier (dashboard → Offerings). Empty = use [Offerings.current].
  static String get revenueCatOfferingIdentifier =>
      AppConfig.revenueCatBusinessOfferingId;

  static bool get gatesPaidBusinessTabs =>
      mode != BusinessOwnerSubscriptionMode.off;
}
