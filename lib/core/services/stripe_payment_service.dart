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
  ///
  /// Native Stripe on Android may fail [Stripe.instance.applySettings] until an Activity exists,
  /// so we retry once after the first frame. [presentPaymentSheet] also calls [applySettings].
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

    Future<bool> tryApply() async {
      try {
        await Stripe.instance.applySettings();
        return true;
      } catch (e, st) {
        debugPrint('Stripe: applySettings failed: $e\n$st');
        return false;
      }
    }

    if (await tryApply()) {
      _initialized = true;
      _debugLogKeyPrefix(publishableKey);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await tryApply()) {
        _initialized = true;
        _debugLogKeyPrefix(publishableKey);
      }
    });
  }

  void _debugLogKeyPrefix(String publishableKey) {
    if (kDebugMode) {
      final prefix = publishableKey.length > 12
          ? '${publishableKey.substring(0, 12)}…'
          : publishableKey;
      debugPrint('Stripe: initialized with publishable key $prefix');
    }
  }

  /// Invokes Supabase Edge Function [STRIPE_PAYMENT_INTENT_FUNCTION] with `{ "order_id": ... }`.
  /// Response includes PaymentSheet session fields (client secret and optional customer data).
  ///
  /// On failure, [StripePaymentSheetFetch.errorMessage] explains what went wrong (e.g. Stripe
  /// rejected the Edge Function’s API key — use **`sk_…` secret key** in Supabase secrets, not `pk_…`).
  Future<StripePaymentSheetFetch> fetchPaymentSheetSession(String orderId) async {
    if (!_initialized) {
      return const StripePaymentSheetFetch(
        session: null,
        errorMessage: 'Stripe is not initialized in the app.',
      );
    }
    try {
      final res = await Supabase.instance.client.functions.invoke(
        _paymentIntentFunction,
        body: {'order_id': orderId},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final apiErr = data['error'];
        if (apiErr != null) {
          return StripePaymentSheetFetch(
            session: null,
            errorMessage: apiErr.toString(),
          );
        }
        final secret = data['clientSecret'] ?? data['client_secret'];
        if (secret is String && secret.isNotEmpty) {
          return StripePaymentSheetFetch(
            session: StripePaymentSheetSession(
              clientSecret: secret,
              paymentIntentId:
                  (data['paymentIntentId'] ?? data['payment_intent_id'])?.toString(),
              customerId: (data['customerId'] ?? data['customer_id'])?.toString(),
              customerEphemeralKeySecret:
                  (data['customerEphemeralKeySecret'] ?? data['ephemeral_key'])?.toString(),
            ),
          );
        }
      }
      debugPrint('Stripe: unexpected edge function response: ${res.data}');
      return const StripePaymentSheetFetch(
        session: null,
        errorMessage:
            'Payment service returned no client secret. Check Edge Function logs and deployment.',
      );
    } catch (e, st) {
      debugPrint('Stripe: create PaymentIntent failed: $e\n$st');
      return StripePaymentSheetFetch(
        session: null,
        errorMessage: _edgeFunctionErrorMessage(e),
      );
    }
  }

  /// Parses [FunctionException] body from `functions.invoke` (Stripe errors often in `details.error`).
  static String _edgeFunctionErrorMessage(Object e) {
    try {
      final dynamic ex = e;
      final details = ex.details;
      if (details is Map) {
        final err = details['error'];
        if (err != null) return err.toString();
      }
      final reason = ex.reasonPhrase;
      if (reason is String && reason.isNotEmpty) return reason;
    } catch (_) {}
    return e.toString();
  }

  /// Presents Stripe PaymentSheet. Returns true if payment succeeded.
  /// Wallets (Apple Pay / Google Pay) appear when enabled for your Stripe account and configured on device.
  Future<bool> presentPaymentSheet({
    required String paymentIntentClientSecret,
    String? customerId,
    String? customerEphemeralKeySecret,
    String merchantDisplayName = 'Habra',
  }) async {
    if (!_initialized) return false;
    try {
      await Stripe.instance.applySettings();
    } catch (e, st) {
      debugPrint(
        'Stripe: applySettings before PaymentSheet failed (check Android theme is '
        'Theme.MaterialComponents / AppCompat per flutter_stripe docs): $e\n$st',
      );
      return false;
    }

    try {
      final PaymentSheetGooglePay? googlePay =
          defaultTargetPlatform == TargetPlatform.android
              ? PaymentSheetGooglePay(
                  merchantCountryCode: _merchantCountry,
                  currencyCode: _paymentCurrency,
                  testEnv: kDebugMode,
                )
              : null;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          customerId: customerId,
          customerEphemeralKeySecret: customerEphemeralKeySecret,
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.light,
          googlePay: googlePay,
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

class StripePaymentSheetSession {
  const StripePaymentSheetSession({
    required this.clientSecret,
    this.paymentIntentId,
    this.customerId,
    this.customerEphemeralKeySecret,
  });

  final String clientSecret;
  final String? paymentIntentId;
  final String? customerId;
  final String? customerEphemeralKeySecret;
}

/// Result of [StripePaymentService.fetchPaymentSheetSession].
class StripePaymentSheetFetch {
  const StripePaymentSheetFetch({
    required this.session,
    this.errorMessage,
  });

  final StripePaymentSheetSession? session;
  final String? errorMessage;
}
