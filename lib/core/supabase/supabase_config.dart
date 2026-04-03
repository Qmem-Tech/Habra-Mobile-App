import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Supabase settings (sourced from [AppConfig] / `--dart-define-from-file`).
///
/// Run with:
///   flutter run --dart-define-from-file=dart_defines.json
/// See [AppConfig] for the full list of keys.
class SupabaseConfig {
  SupabaseConfig._();

  static String get supabaseUrl => AppConfig.supabaseUrl;

  static String get supabaseAnonKey => AppConfig.supabaseAnonKey;

  static bool get isConfigured => AppConfig.isSupabaseConfigured;

  /// Mobile deep link passed to Supabase `emailRedirectTo` / `redirectTo`.
  /// Must appear in Supabase Dashboard → Authentication → URL Configuration → Redirect URLs.
  /// For desktop/browser confirmation flows, add the same project’s HTTPS callback URL there
  /// and use email templates that open the web callback; the app still uses this for in-app sign-up.
  static String get authRedirectUrl => AppConfig.supabaseAuthRedirectUrl;

  /// Call before Supabase.initialize(); throws if not configured (in release/debug).
  static void assertConfigured() {
    if (!isConfigured) {
      if (kReleaseMode) {
        throw StateError(
          'Supabase URL and anon key must be set via --dart-define (see AppConfig / dart_defines.json).',
        );
      }
      throw StateError(
        'Supabase not configured. Use --dart-define-from-file=dart_defines.json or individual --dart-define flags.',
      );
    }
  }
}
