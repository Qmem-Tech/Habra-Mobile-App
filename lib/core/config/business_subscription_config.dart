import 'app_config.dart';

/// Feature flags for business-owner paid tools (Dashboard, Boosts).
///
/// Set via `--dart-define=BUSINESS_OWNER_SUBSCRIPTION_MODE=...` ([AppConfig]).
///
/// - **off**: No subscription gate (legacy fallback).
/// - **revenuecat**: Gate on RevenueCat entitlement [revenueCatEntitlementId].
/// - **stub_locked**: Always locked (QA / UI testing).
enum BusinessOwnerSubscriptionMode {
  off,
  revenuecat,
  stubLocked,
}

class BusinessSubscriptionConfig {
  BusinessSubscriptionConfig._();

  static BusinessOwnerSubscriptionMode get mode {
    final raw = AppConfig.businessOwnerSubscriptionMode;
    switch (raw) {
      case 'off':
        return BusinessOwnerSubscriptionMode.off;
      case 'revenuecat':
        return BusinessOwnerSubscriptionMode.revenuecat;
      case 'profile':
        // Backward compatibility for old sandbox configs.
        return BusinessOwnerSubscriptionMode.revenuecat;
      case 'stub_locked':
        return BusinessOwnerSubscriptionMode.stubLocked;
      default:
        return BusinessOwnerSubscriptionMode.revenuecat;
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
