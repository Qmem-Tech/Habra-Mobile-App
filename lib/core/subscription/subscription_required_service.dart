import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads `app_settings.subscription_required`.
///
/// When `false`, all business owners bypass paid subscription (same effect as
/// per-user `profiles.subscription_bypass` for everyone).
class SubscriptionRequiredService {
  SubscriptionRequiredService();

  SupabaseClient get _client => Supabase.instance.client;

  /// Defaults to `true` (subscription required) if the row is missing or fetch fails.
  Future<bool> isSubscriptionRequired() async {
    try {
      final row = await _client
          .from('app_settings')
          .select('value')
          .eq('key', 'subscription_required')
          .maybeSingle();
      if (row == null) return true;
      return _parseBool(row['value'], defaultValue: true);
    } catch (e) {
      debugPrint('[SubscriptionRequired] fetch failed: $e');
      return true;
    }
  }

  static bool _parseBool(dynamic value, {required bool defaultValue}) {
    if (value == true) return true;
    if (value == false) return false;
    if (value is String) {
      final s = value.toLowerCase().trim();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    if (value is num) return value != 0;
    return defaultValue;
  }
}
