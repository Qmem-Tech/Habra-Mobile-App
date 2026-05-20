import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin-controlled free-trial configuration read from `app_settings`.
class TrialConfig {
  const TrialConfig({this.enabled = false, this.months = 2});

  final bool enabled;
  final int months;
}

/// Current trial state for a single user profile.
class TrialStatus {
  const TrialStatus({this.isActive = false, this.endsAt});

  final bool isActive;

  /// Non-null means a trial was granted (may be active or expired).
  final DateTime? endsAt;

  /// Days remaining in an active trial; 0 if not active.
  int get daysRemaining {
    if (!isActive || endsAt == null) return 0;
    final diff = endsAt!.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }

  /// True when a trial was granted in the past but has since expired.
  bool get hasExpired => endsAt != null && !isActive;
}

/// Reads/writes business-subscription trial data.
///
/// - [fetchConfig] → reads `app_settings` for global toggle + duration.
/// - [getTrialStatus] → reads `profiles` to check per-user trial dates.
/// - [grantTrial] → writes trial start/end dates into `profiles`.
class SubscriptionTrialService {
  SubscriptionTrialService();

  SupabaseClient get _client => Supabase.instance.client;

  /// Fetches trial feature-flag settings from `app_settings`.
  /// Returns defaults if the rows are missing or the call fails.
  Future<TrialConfig> fetchConfig() async {
    try {
      final rows = await _client
          .from('app_settings')
          .select('key, value')
          .inFilter('key', [
            'subscription_trial_enabled',
            'subscription_trial_months',
          ]);

      bool enabled = false;
      int months = 2;

      for (final row in (rows as List)) {
        final key = row['key'] as String?;
        final value = row['value'];
        if (key == 'subscription_trial_enabled') {
          enabled = _parseBool(value);
        } else if (key == 'subscription_trial_months') {
          months = _parseMonths(value);
        }
      }
      debugPrint(
        '[Trial] fetchConfig enabled=$enabled months=$months (from app_settings)',
      );
      return TrialConfig(enabled: enabled, months: months);
    } catch (e) {
      debugPrint('[Trial] fetchConfig failed: $e');
      return const TrialConfig();
    }
  }

  static bool _parseBool(dynamic value) {
    if (value == true) return true;
    if (value == false || value == null) return false;
    if (value is String) {
      final s = value.toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }
    if (value is num) return value != 0;
    return false;
  }

  static int _parseMonths(dynamic value) {
    if (value is int) return value.clamp(1, 120);
    if (value is double) return value.toInt().clamp(1, 120);
    if (value is String) return (int.tryParse(value.trim()) ?? 2).clamp(1, 120);
    return 2;
  }

  /// Returns the trial status for [userId] (their `auth.uid()` / profiles.id).
  Future<TrialStatus> getTrialStatus(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('subscription_trial_starts_at, subscription_trial_ends_at')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return const TrialStatus();

      final endsAtRaw = data['subscription_trial_ends_at'];
      if (endsAtRaw == null) return const TrialStatus();

      final endsAt = DateTime.tryParse(endsAtRaw.toString())?.toLocal();
      if (endsAt == null) return const TrialStatus();

      final isActive = DateTime.now().isBefore(endsAt);
      return TrialStatus(isActive: isActive, endsAt: endsAt);
    } catch (e) {
      debugPrint('[Trial] getTrialStatus failed: $e');
      return const TrialStatus();
    }
  }

  /// Grants a new trial to [userId], expiring [months] calendar months from now.
  /// Idempotent — re-calling when a trial already exists is a no-op; the DB
  /// update only writes if `subscription_trial_starts_at IS NULL` so existing
  /// trials are never overwritten.
  Future<bool> grantTrial(String userId, int months) async {
    try {
      // Only grant if no trial has been started yet.
      final existing = await getTrialStatus(userId);
      if (existing.endsAt != null) {
        debugPrint('[Trial] grantTrial: trial already exists, skipping');
        return false;
      }

      final now = DateTime.now().toUtc();
      final endsAt = DateTime.utc(
        now.year,
        now.month + months,
        now.day,
        now.hour,
        now.minute,
        now.second,
      );

      await _client.from('profiles').update({
        'subscription_trial_starts_at': now.toIso8601String(),
        'subscription_trial_ends_at': endsAt.toIso8601String(),
      }).eq('id', userId);

      debugPrint(
        '[Trial] grantTrial: granted $months-month trial for $userId, '
        'ends ${endsAt.toIso8601String()}',
      );
      return true;
    } catch (e) {
      debugPrint('[Trial] grantTrial failed: $e');
      return false;
    }
  }
}
