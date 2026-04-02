import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat service for in-app purchases (boosts, tickets).
///
/// **Use the platform public SDK key only** (RevenueCat dashboard → Project settings →
/// API keys → **Public app-specific API key** for Android / iOS). Never put the
/// **secret** API key in the app; the backend returns error **7243** if you do
/// ("Secret API keys should not be used in your app").
///
/// Configure keys via `--dart-define=REVENUECAT_ANDROID_API_KEY=...` in [main].
/// Free tier: https://www.revenuecat.com/pricing/
class RevenueCatService {
  RevenueCatService();

  static const String _androidApiKey = 'YOUR_REVENUECAT_ANDROID_API_KEY';
  static const String _iosApiKey = 'YOUR_REVENUECAT_IOS_API_KEY';

  bool _initialized = false;
  String? _configuredApiKey;

  /// Call before runApp. Pass platform-specific API key from env/config.
  Future<bool> initialize({
    String? androidApiKey,
    String? iosApiKey,
  }) async {
    if (_initialized) return true;

    final apiKey = defaultTargetPlatform == TargetPlatform.android
        ? (androidApiKey ?? _androidApiKey)
        : (iosApiKey ?? _iosApiKey);
    if (apiKey.isEmpty ||
        apiKey == _androidApiKey ||
        apiKey == _iosApiKey) {
      debugPrint('RevenueCat not initialized: missing platform API key.');
      return false;
    }

    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));

    _initialized = true;
    _configuredApiKey = apiKey;
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
  Future<bool> purchasePackage(Package package) async {
    if (!_initialized) return false;
    try {
      final purchaserInfo = await Purchases.purchasePackage(package);
      return purchaserInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      debugPrint('RevenueCat purchase error: $e');
      return false;
    }
  }

  /// Check if user has active entitlement (e.g. for premium features).
  Future<bool> hasEntitlement(String entitlementId) async {
    if (!_initialized) return false;
    try {
      final purchaserInfo = await Purchases.getCustomerInfo();
      return purchaserInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('RevenueCat hasEntitlement error: $e');
      return false;
    }
  }

  /// Packages to sell business-owner tools. Uses [offeringIdentifier] if set, else current offering.
  Future<List<Package>> getOwnerToolsPackages({String? offeringIdentifier}) async {
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

  /// Identify user after login (optional, for cross-device).
  Future<void> identifyUser(String userId, {String? email}) async {
    if (!_initialized) return;
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('RevenueCat identifyUser error: $e');
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
}
