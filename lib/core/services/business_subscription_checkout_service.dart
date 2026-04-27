import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../subscription/business_subscription_tier.dart';

class BusinessSubscriptionCheckoutService {
  BusinessSubscriptionCheckoutService();

  SupabaseClient get _client => Supabase.instance.client;

  Future<Uri?> createCheckoutUrl(BusinessSubscriptionTier tier) async {
    final fn = AppConfig.stripeBusinessSubscriptionCheckoutFunction;
    if (fn.trim().isEmpty) return null;
    try {
      final res = await _client.functions.invoke(
        fn,
        body: {
          'tier': tier.name,
          'success_url': AppConfig.stripeBusinessSubscriptionSuccessUrl,
          'cancel_url': AppConfig.stripeBusinessSubscriptionCancelUrl,
        },
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) return null;
      final rawUrl = data['url']?.toString();
      if (rawUrl == null || rawUrl.trim().isEmpty) return null;
      return Uri.tryParse(rawUrl.trim());
    } catch (e) {
      debugPrint('BusinessSubscriptionCheckoutService createCheckoutUrl: $e');
      return null;
    }
  }

  Future<bool> openCheckout(BusinessSubscriptionTier tier) async {
    final url = await createCheckoutUrl(tier);
    if (url == null) return false;
    return launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<Uri?> createPortalUrl() async {
    final fn = AppConfig.stripeBusinessSubscriptionPortalFunction;
    if (fn.trim().isEmpty) return null;
    try {
      final res = await _client.functions.invoke(
        fn,
        body: {
          'return_url': AppConfig.stripeBusinessSubscriptionCancelUrl,
        },
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) return null;
      final rawUrl = data['url']?.toString();
      if (rawUrl == null || rawUrl.trim().isEmpty) return null;
      return Uri.tryParse(rawUrl.trim());
    } catch (e) {
      debugPrint('BusinessSubscriptionCheckoutService createPortalUrl: $e');
      return null;
    }
  }

  Future<bool> openPortal() async {
    final url = await createPortalUrl();
    if (url == null) return false;
    return launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }
}
