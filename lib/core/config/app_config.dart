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
/// **Note:** Some keys still live in native config (e.g. Google Maps
/// `com.google.android.geo.API_KEY` in `AndroidManifest.xml`). Keep those in sync
/// with your team’s secrets process.
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

  // --- RevenueCat ---
  static const String revenueCatAndroidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
    defaultValue: '',
  );

  static const String revenueCatIosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
    defaultValue: '',
  );

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
