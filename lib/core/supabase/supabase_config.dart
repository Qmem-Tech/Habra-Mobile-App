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
