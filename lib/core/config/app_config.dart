import 'revenue_cat_sdk_keys.dart';

/// Single place for **app-side** secrets and build-time tunables.
///
/// Values come from `--dart-define=KEY=value` or, for local dev, one JSON file:
///
/// ```bash
/// flutter run --dart-define-from-file=dart_defines.json
/// ```
///
/// Copy [dart_defines.example.json] at the project root to `dart_defines.json`,
/// fill in your keys, and add `dart_defines.json` to `.gitignore` if it is not already.
///
/// **Google Maps:** Set `GOOGLE_MAPS_API_KEY` in `dart_defines.json` (see
/// [AppConfig.googleMapsApiKey]). Android reads the same file in Gradle; iOS
/// generates `ios/Flutter/MapsKey.generated.xcconfig` on `pod install`. Legacy
/// alias: `MAPS_SDK_API_KEY`.
///
/// **Google Sign-In on iOS:** Set `GOOGLE_IOS_CLIENT_ID` (iOS OAuth client ID in
/// Cloud Console for your bundle ID). `pod install` writes
/// `ios/Flutter/GoogleSignInIos.generated.xcconfig` for `GIDClientID` and the
/// reversed URL scheme in Info.plist. Keep `GOOGLE_WEB_CLIENT_ID` for Supabase.
///
/// **RevenueCat:** Public SDK keys live in [RevenueCatSdkKeys] (`lib/core/config/revenue_cat_sdk_keys.dart`).
class AppConfig {
  AppConfig._();

  // --- Supabase ---
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String supabaseAuthRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
    defaultValue: 'habra://auth/callback',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // --- Google Sign-In (Supabase OAuth) ---
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// iOS OAuth client ID (`*.apps.googleusercontent.com`) from Google Cloud Console.
  /// Required on iOS: Google Sign-In 8.x reads [GIDClientID] from Info.plist; set
  /// `GOOGLE_IOS_CLIENT_ID` in `dart_defines.json` (synced on `pod install`).
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  /// Native Maps SDK (same key as Android manifest / iOS `GMSApiKey` in Info.plist).
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const String _mapsSdkApiKeyAlias = String.fromEnvironment(
    'MAPS_SDK_API_KEY',
    defaultValue: '',
  );

  /// Resolves [googleMapsApiKey], or [MAPS_SDK_API_KEY] if the primary define is empty.
  static String get effectiveGoogleMapsApiKey =>
      googleMapsApiKey.isNotEmpty ? googleMapsApiKey : _mapsSdkApiKeyAlias;

  static bool get isGoogleMapsConfigured => effectiveGoogleMapsApiKey.isNotEmpty;

  // --- RevenueCat (in-source keys; see [RevenueCatSdkKeys]) ---
  static String get revenueCatAndroidApiKey => RevenueCatSdkKeys.android;

  static String get revenueCatIosApiKey => RevenueCatSdkKeys.ios;

  // --- Stripe (PaymentSheet / event tickets) ---
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const String stripeMerchantId = String.fromEnvironment(
    'STRIPE_MERCHANT_ID',
    defaultValue: '',
  );

  static const String stripePaymentIntentFunction = String.fromEnvironment(
    'STRIPE_PAYMENT_INTENT_FUNCTION',
    defaultValue: 'create-event-payment-intent',
  );

  /// Edge Function: finalize order from Stripe immediately after Payment Sheet (fast path).
  static const String stripeSyncOrderPaymentFunction = String.fromEnvironment(
    'STRIPE_SYNC_ORDER_PAYMENT_FUNCTION',
    defaultValue: 'sync-event-order-payment',
  );
  static const String stripeBusinessSubscriptionCheckoutFunction =
      String.fromEnvironment(
    'STRIPE_BUSINESS_SUBSCRIPTION_CHECKOUT_FUNCTION',
    defaultValue: 'create-business-subscription-checkout',
  );
  static const String stripeBusinessSubscriptionPortalFunction =
      String.fromEnvironment(
    'STRIPE_BUSINESS_SUBSCRIPTION_PORTAL_FUNCTION',
    defaultValue: 'create-business-subscription-portal',
  );
  static const String stripeBusinessSubscriptionSuccessUrl =
      String.fromEnvironment(
    'STRIPE_BUSINESS_SUBSCRIPTION_SUCCESS_URL',
    defaultValue: 'https://example.com/subscription/success',
  );
  static const String stripeBusinessSubscriptionCancelUrl =
      String.fromEnvironment(
    'STRIPE_BUSINESS_SUBSCRIPTION_CANCEL_URL',
    defaultValue: 'https://example.com/subscription/cancel',
  );

  static const String stripeMerchantCountry = String.fromEnvironment(
    'STRIPE_MERCHANT_COUNTRY',
    defaultValue: 'US',
  );

  static const String stripePaymentCurrency = String.fromEnvironment(
    'STRIPE_PAYMENT_CURRENCY',
    defaultValue: 'USD',
  );

  // --- Business owner subscription (see [BusinessSubscriptionConfig]) ---
  static const String businessOwnerSubscriptionMode = String.fromEnvironment(
    'BUSINESS_OWNER_SUBSCRIPTION_MODE',
    defaultValue: 'off',
  );

  static const String revenueCatBusinessEntitlementId = String.fromEnvironment(
    'REVENUECAT_BUSINESS_ENTITLEMENT_ID',
    defaultValue: 'business_owner_tools',
  );

  static const String revenueCatBusinessOfferingId = String.fromEnvironment(
    'REVENUECAT_BUSINESS_OFFERING_ID',
    defaultValue: '',
  );

  /// RevenueCat offering that contains boost IAP packages (optional; if empty, all offerings are searched).
  static const String revenueCatBoostOfferingId = String.fromEnvironment(
    'REVENUECAT_BOOST_OFFERING_ID',
    defaultValue: '',
  );

  // --- Misc ---
  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: '',
  );

  static const String notificationsUserIdColumn = String.fromEnvironment(
    'NOTIFICATIONS_USER_ID_COLUMN',
    defaultValue: 'user_id',
  );
}
