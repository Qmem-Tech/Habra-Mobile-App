import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Stripe PaymentSheet for **event tickets** (card, Apple Pay, Google Pay when enabled).
///
/// Requires:
/// - [publishableKey] (pk_test_… / pk_live_…) via `--dart-define=STRIPE_PUBLISHABLE_KEY=...`
/// - A Supabase Edge Function (or other backend) that creates a PaymentIntent and returns `clientSecret`.
/// - Optional: `--dart-define=STRIPE_MERCHANT_COUNTRY=US` and `STRIPE_PAYMENT_CURRENCY=USD` for wallet config.
///
/// Secret keys and webhook verification must **never** ship in the app; they live on the server.
class StripePaymentService {
  StripePaymentService();

  static String get _paymentIntentFunction =>
      AppConfig.stripePaymentIntentFunction;

  static String get _merchantCountry => AppConfig.stripeMerchantCountry;

  static String get _paymentCurrency => AppConfig.stripePaymentCurrency;

  bool _initialized = false;

  /// True when a publishable key was applied and Stripe SDK is ready.
  bool get isConfigured => _initialized;

  /// Call from [main] after [WidgetsFlutterBinding.ensureInitialized].
  Future<void> initialize({
    required String publishableKey,
    String? merchantIdentifier,
  }) async {
    if (publishableKey.isEmpty) {
      debugPrint(
        'Stripe: STRIPE_PUBLISHABLE_KEY not set; event checkout will use debug fallback or fail in release.',
      );
      return;
    }
    Stripe.publishableKey = publishableKey;
    if (merchantIdentifier != null && merchantIdentifier.isNotEmpty) {
      Stripe.merchantIdentifier = merchantIdentifier;
    }
    _initialized = true;
  }

  /// Invokes Supabase Edge Function [STRIPE_PAYMENT_INTENT_FUNCTION] with `{ "order_id": ... }`.
  /// Response must include `clientSecret` (or `client_secret`) for PaymentSheet.
  Future<String?> fetchPaymentIntentClientSecret(String orderId) async {
    if (!_initialized) return null;
    try {
      final res = await Supabase.instance.client.functions.invoke(
        _paymentIntentFunction,
        body: {'order_id': orderId},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final secret = data['clientSecret'] ?? data['client_secret'];
        if (secret is String && secret.isNotEmpty) return secret;
      }
      debugPrint('Stripe: unexpected edge function response: ${res.data}');
      return null;
    } catch (e, st) {
      debugPrint('Stripe: create PaymentIntent failed: $e\n$st');
      return null;
    }
  }

  /// Presents Stripe PaymentSheet. Returns true if payment succeeded.
  /// Wallets (Apple Pay / Google Pay) appear when enabled for your Stripe account and configured on device.
  Future<bool> presentPaymentSheet({
    required String paymentIntentClientSecret,
    String merchantDisplayName = 'Habra',
  }) async {
    if (!_initialized) return false;
    try {
      final PaymentSheetGooglePay? googlePay =
          defaultTargetPlatform == TargetPlatform.android
              ? PaymentSheetGooglePay(
                  merchantCountryCode: _merchantCountry,
                  currencyCode: _paymentCurrency,
                  testEnv: kDebugMode,
                )
              : null;

      final PaymentSheetApplePay? applePay =
          defaultTargetPlatform == TargetPlatform.iOS
              ? PaymentSheetApplePay(merchantCountryCode: _merchantCountry)
              : null;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.light,
          googlePay: googlePay,
          applePay: applePay,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      debugPrint('Stripe PaymentSheet: ${e.error.code} ${e.error.message}');
      return false;
    } catch (e) {
      debugPrint('Stripe PaymentSheet error: $e');
      return false;
    }
  }
}
