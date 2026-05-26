import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/business_subscription_config.dart';
import '../subscription/business_subscription_tier.dart';
import '../subscription/subscription_logger.dart';

/// Outcome of a one-time boost purchase (consumable / non-entitlement IAP).
class BoostIapResult {
  const BoostIapResult({
    this.completed = false,
    this.userCancelled = false,
    this.errorMessage,
  });

  final bool completed;
  final bool userCancelled;
  final String? errorMessage;
}

/// RevenueCat service for in-app purchases (boosts, tickets).
///
/// **Use the platform public SDK key only** (RevenueCat dashboard → Project settings →
/// API keys → **Public app-specific API key** for Android / iOS). Never put the
/// **secret** API key in the app; the backend returns error **7243** if you do
/// ("Secret API keys should not be used in your app").
///
/// Configure keys via `dart_defines.json` and `--dart-define-from-file` (see [AppConfig]).
/// Free tier: https://www.revenuecat.com/pricing/
class RevenueCatService {
  RevenueCatService();

  bool _initialized = false;
  String? _configuredApiKey;

  /// Call before runApp. Pass platform-specific **public** SDK keys from [AppConfig]
  /// ([RevenueCatSdkKeys] in `lib/core/config/revenue_cat_sdk_keys.dart`).
  Future<bool> initialize({String? androidApiKey, String? iosApiKey}) async {
    if (_initialized) return true;

    final raw = defaultTargetPlatform == TargetPlatform.android
        ? (androidApiKey ?? '').trim()
        : (iosApiKey ?? '').trim();

    if (raw.isEmpty) {
      debugPrint(
        'RevenueCat not initialized: missing platform API key. '
        'Set RevenueCatSdkKeys.android / RevenueCatSdkKeys.ios in '
        'lib/core/config/revenue_cat_sdk_keys.dart '
        '(RevenueCat dashboard → Project settings → API keys → Public app-specific key).',
      );
      return false;
    }

    const knownPlaceholders = {
      'YOUR_REVENUECAT_ANDROID_API_KEY',
      'YOUR_REVENUECAT_IOS_API_KEY',
    };
    if (knownPlaceholders.contains(raw)) {
      debugPrint('RevenueCat not initialized: replace placeholder API key in config.');
      return false;
    }

    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(raw));

    _initialized = true;
    _configuredApiKey = raw;
    return true;
  }

  bool get isInitialized => _initialized;
  String? get configuredApiKey => _configuredApiKey;

  /// Get available offerings (boost plans, etc.).
  Future<Offerings?> getOfferings() async {
    if (!_initialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('RevenueCat getOfferings error: $e');
      return null;
    }
  }

  /// Purchase a package. Returns true if successful.
  ///
  /// After a successful StoreKit transaction, RevenueCat's server can take a
  /// few seconds to process the receipt and activate the entitlement. This
  /// method retries [_maxEntitlementRetries] times with a short delay so the
  /// caller doesn't see a false "Purchase incomplete" on a valid purchase.
  static const int _maxEntitlementRetries = 4;
  static const Duration _entitlementRetryDelay = Duration(seconds: 2);

  Future<bool> purchasePackage(Package package) async {
    if (!_initialized) return false;

    var sdkThrew = false;
    try {
      await Purchases.purchasePackage(package);
    } on PlatformException catch (e) {
      if (_isUserCancelledPurchase(e)) {
        debugPrint('[RC] purchasePackage: user cancelled');
        return false;
      }
      sdkThrew = true;
      debugPrint(
        '[RC] purchasePackage PlatformException (verifying subscription): $e',
      );
    } catch (e) {
      sdkThrew = true;
      debugPrint('[RC] purchasePackage error (verifying subscription): $e');
    }

    final active = await _waitForActiveBusinessSubscription(
      logLabel: sdkThrew ? 'post-sdk-error' : 'post-purchase',
    );
    if (active && sdkThrew) {
      debugPrint(
        '[RC] purchasePackage: subscription active despite SDK error',
      );
    }
    return active;
  }

  bool _isUserCancelledPurchase(PlatformException e) {
    try {
      return PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError;
    } catch (_) {
      return false;
    }
  }

  /// After purchase (or a benign SDK error), poll until RC reports an active sub.
  Future<bool> _waitForActiveBusinessSubscription({
    required String logLabel,
  }) async {
    final entitlementId = BusinessSubscriptionConfig.revenueCatEntitlementId;

    for (int attempt = 1; attempt <= _maxEntitlementRetries; attempt++) {
      try {
        try {
          await Purchases.syncPurchases();
        } catch (_) {}

        final info = await Purchases.getCustomerInfo();
        debugPrint(
          '[RC] $logLabel attempt $attempt — '
          'activeSubscriptions: ${info.activeSubscriptions}, '
          'activeEntitlements: ${info.entitlements.active.keys.toList()}',
        );
        if (_customerInfoHasBusinessSubscription(info, entitlementId)) {
          return true;
        }
      } catch (e) {
        debugPrint('[RC] $logLabel getCustomerInfo error on attempt $attempt: $e');
      }
      if (attempt < _maxEntitlementRetries) {
        await Future.delayed(_entitlementRetryDelay);
      }
    }
    return false;
  }

  bool _customerInfoHasBusinessSubscription(
    CustomerInfo info,
    String entitlementId,
  ) {
    if (info.entitlements.all[entitlementId]?.isActive == true) return true;
    if (info.entitlements.active.isNotEmpty) return true;
    if (info.activeSubscriptions.any(
      (id) => _businessProductIds.any((p) => id.contains(p)),
    )) {
      return true;
    }
    return info.activeSubscriptions.isNotEmpty;
  }

  /// Business subscription product IDs — used as fallback when RevenueCat's
  /// entitlement map lags behind or has a product-ID suffix mismatch.
  static const _businessProductIds = {
    'habra_standard_monthly',
    'habra_standard_yearly',
    'habra_premium_monthly',
    'habra_premium_yearly',
  };

  /// Check if user has active entitlement (e.g. for premium features).
  ///
  /// Pass [forceRefresh] = true to bypass the SDK cache and fetch directly
  /// from RevenueCat's server (use after a purchase or restore).
  Future<bool> hasEntitlement(String entitlementId,
      {bool forceRefresh = false}) async {
    if (!_initialized) return false;
    try {
      if (forceRefresh) {
        try {
          await Purchases.syncPurchases();
        } catch (_) {}
      }
      final info = await Purchases.getCustomerInfo();
      debugPrint(
        '[RC] hasEntitlement("$entitlementId") — '
        'active: ${info.entitlements.all[entitlementId]?.isActive}, '
        'activeSubscriptions: ${info.activeSubscriptions}',
      );
      if (_customerInfoHasBusinessSubscription(info, entitlementId)) {
        if (info.entitlements.all[entitlementId]?.isActive != true) {
          debugPrint(
            '[RC] hasEntitlement fallback: granted via activeSubscriptions',
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('RevenueCat hasEntitlement error: $e');
      return false;
    }
  }

  /// Finds a RevenueCat [Package] whose store product id matches [storeProductId].
  ///
  /// Searches [offeringIdentifier] first (if non-empty), then [Offerings.current],
  /// then every offering. Used with [boost_plans.billing_product_id].
  Future<Package?> findPackageByStoreProductId(
    String storeProductId, {
    String? offeringIdentifier,
  }) async {
    if (!_initialized || storeProductId.trim().isEmpty) return null;
    try {
      final offerings = await Purchases.getOfferings();
      final targetId = storeProductId.trim();
      Package? match(Iterable<Package> packages) {
        for (final p in packages) {
          if (p.storeProduct.identifier == targetId) return p;
        }
        return null;
      }

      final id = offeringIdentifier?.trim() ?? '';
      if (id.isNotEmpty) {
        final o = offerings.all[id];
        if (o != null) {
          final m = match(o.availablePackages);
          if (m != null) return m;
        }
      }

      final current = offerings.current;
      if (current != null) {
        final m = match(current.availablePackages);
        if (m != null) return m;
      }

      for (final o in offerings.all.values) {
        final m = match(o.availablePackages);
        if (m != null) return m;
      }
      return null;
    } catch (e) {
      debugPrint('RevenueCat findPackageByStoreProductId error: $e');
      return null;
    }
  }

  /// Returns a map of offering id -> store product identifiers available in that offering.
  /// Useful for debugging boost plan/store mapping mismatches.
  Future<Map<String, List<String>>> listOfferingProductIds() async {
    if (!_initialized) return const {};
    try {
      final offerings = await Purchases.getOfferings();
      final result = <String, List<String>>{};
      offerings.all.forEach((offeringId, offering) {
        result[offeringId] = offering.availablePackages
            .map((p) => p.storeProduct.identifier)
            .toList(growable: false);
      });
      return result;
    } catch (e) {
      debugPrint('RevenueCat listOfferingProductIds error: $e');
      return const {};
    }
  }

  /// Completes a boost IAP without requiring an active entitlement (unlike subscriptions).
  Future<BoostIapResult> purchaseBoostPackage(Package package) async {
    if (!_initialized) {
      return const BoostIapResult(
        errorMessage: 'In-app purchases are not configured for this build.',
      );
    }
    try {
      await Purchases.purchasePackage(package);
      return const BoostIapResult(completed: true);
    } on PlatformException catch (e) {
      try {
        final code = PurchasesErrorHelper.getErrorCode(e);
        if (code == PurchasesErrorCode.purchaseCancelledError) {
          return const BoostIapResult(userCancelled: true);
        }
      } catch (_) {
        // Fall through — malformed code from platform
      }
      return BoostIapResult(
        errorMessage: e.message?.isNotEmpty == true ? e.message! : e.toString(),
      );
    } catch (e) {
      debugPrint('RevenueCat purchaseBoostPackage error: $e');
      return BoostIapResult(errorMessage: e.toString());
    }
  }

  /// Packages to sell business-owner tools. Uses [offeringIdentifier] if set, else current offering.
  Future<List<Package>> getOwnerToolsPackages({
    String? offeringIdentifier,
  }) async {
    if (!_initialized) return [];
    try {
      final offerings = await Purchases.getOfferings();
      Offering? offering;
      final id = offeringIdentifier?.trim() ?? '';
      if (id.isNotEmpty) {
        offering = offerings.all[id];
      }
      offering ??= offerings.current;
      if (offering == null && offerings.all.isNotEmpty) {
        offering = offerings.all.values.first;
      }
      return offering?.availablePackages ?? [];
    } catch (e) {
      debugPrint('RevenueCat getOwnerToolsPackages error: $e');
      return [];
    }
  }

  /// Restore purchases (e.g. new device). Caller should re-check entitlements afterward.
  Future<void> restorePurchases() async {
    if (!_initialized) return;
    try {
      await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('RevenueCat restorePurchases error: $e');
      rethrow;
    }
  }

  /// Identify user after login (links app user id to RevenueCat customer).
  ///
  /// Mirrors Tactix: [Purchases.logIn], subscriber attributes (`$email`, `$displayName`),
  /// then [Purchases.restorePurchases] so store subscriptions sync on new devices.
  Future<void> identifyUser(
    String userId, {
    String? email,
    String? displayName,
  }) async {
    if (!_initialized) return;
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('RevenueCat identifyUser logIn error: $e');
      return;
    }

    try {
      final attrs = <String, String>{};
      final trimmedEmail = email?.trim() ?? '';
      if (trimmedEmail.isNotEmpty) {
        attrs[r'$email'] = trimmedEmail;
      }
      final trimmedName = displayName?.trim() ?? '';
      if (trimmedName.isNotEmpty) {
        attrs[r'$displayName'] = trimmedName;
      }
      if (attrs.isNotEmpty) {
        await Purchases.setAttributes(attrs);
      }
    } catch (e) {
      debugPrint('RevenueCat setAttributes error: $e');
    }

    try {
      await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('RevenueCat identifyUser restorePurchases error: $e');
      try {
        await Purchases.getCustomerInfo();
      } catch (_) {
        // ignore
      }
    }
  }

  /// Log out (e.g. on app logout).
  Future<void> logout() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logout error: $e');
    }
  }

  Future<BusinessSubscriptionTier> resolveCurrentTier() async {
    if (!_initialized) return BusinessSubscriptionTier.basic;
    try {
      final info = await Purchases.getCustomerInfo();
      // Use only activeSubscriptions (product IDs) — not entitlement keys,
      // which can contain words like "production" that falsely match "pro".
      final productIds = info.activeSubscriptions
          .map((e) => e.toLowerCase())
          .toList();
      debugPrint('[RC] resolveCurrentTier — productIds: $productIds');
      final BusinessSubscriptionTier tier;
      if (productIds.any((e) => e.contains('premium'))) {
        tier = BusinessSubscriptionTier.premium;
      } else if (productIds.any((e) => e.contains('standard'))) {
        // habra_standard_* products map to the mid (pro) tier.
        tier = BusinessSubscriptionTier.pro;
      } else {
        tier = BusinessSubscriptionTier.basic;
      }
      subscriptionLog(
        'RevenueCat plan: ${tier.displayName} (tier=${tier.name}, products=$productIds)',
      );
      return tier;
    } catch (e) {
      subscriptionLog('RevenueCat resolveCurrentTier failed: $e → Basic');
      return BusinessSubscriptionTier.basic;
    }
  }
}
