/// Feature flags for business-owner paid tools (Dashboard, Boosts).
///
/// Set via `--dart-define=BUSINESS_OWNER_SUBSCRIPTION_MODE=...`
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
    const raw = String.fromEnvironment(
      'BUSINESS_OWNER_SUBSCRIPTION_MODE',
      defaultValue: 'off',
    );
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
  static const String revenueCatEntitlementId = String.fromEnvironment(
    'REVENUECAT_BUSINESS_ENTITLEMENT_ID',
    defaultValue: 'business_owner_tools',
  );

  static bool get gatesPaidBusinessTabs =>
      mode != BusinessOwnerSubscriptionMode.off;
}
