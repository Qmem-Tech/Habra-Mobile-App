import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat service for in-app purchases (boosts, tickets).
/// Configure API keys in main.dart before runApp.
/// Free tier: https://www.revenuecat.com/pricing/
class RevenueCatService {
  RevenueCatService();

  static const String _androidApiKey = 'YOUR_REVENUECAT_ANDROID_API_KEY';
  static const String _iosApiKey = 'YOUR_REVENUECAT_IOS_API_KEY';

  bool _initialized = false;

  /// Call before runApp. Pass platform-specific API key from env/config.
  Future<void> initialize({
    String? androidApiKey,
    String? iosApiKey,
  }) async {
    if (_initialized) return;

    final apiKey = defaultTargetPlatform == TargetPlatform.android
        ? (androidApiKey ?? _androidApiKey)
        : (iosApiKey ?? _iosApiKey);

    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));

    _initialized = true;
  }

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
