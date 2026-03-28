import 'package:flutter/foundation.dart';

/// Supabase configuration from dart-define or default placeholders.
///
/// Run with:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key
/// Or set in IDE run configuration.
class SupabaseConfig {
  SupabaseConfig._();

  static String get supabaseUrl {
    const value = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    return value;
  }

  static String get supabaseAnonKey {
    const value = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );
    return value;
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Mobile deep link passed to Supabase `emailRedirectTo` / `redirectTo`.
  /// Must appear in Supabase Dashboard → Authentication → URL Configuration → Redirect URLs.
  /// For desktop/browser confirmation flows, add the same project’s HTTPS callback URL there
  /// and use email templates that open the web callback; the app still uses this for in-app sign-up.
  static const String authRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
    defaultValue: 'habra://auth/callback',
  );

  /// Call before Supabase.initialize(); throws if not configured (in release/debug).
  static void assertConfigured() {
    if (!isConfigured) {
      if (kReleaseMode) {
        throw StateError(
          'Supabase URL and anon key must be set via --dart-define.',
        );
      }
      throw StateError(
        'Supabase not configured. Run with --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
      );
    }
  }
}
