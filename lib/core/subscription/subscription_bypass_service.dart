import 'package:supabase_flutter/supabase_flutter.dart';

import 'business_subscription_tier.dart';

/// Per-user bypass flag from `profiles.subscription_bypass` (super-admin only).
class SubscriptionBypassSnapshot {
  const SubscriptionBypassSnapshot({
    this.bypass = false,
    this.profileTier = BusinessSubscriptionTier.basic,
  });

  final bool bypass;
  final BusinessSubscriptionTier profileTier;
}

class SubscriptionBypassService {
  SubscriptionBypassService();

  SupabaseClient get _client => Supabase.instance.client;

  Future<SubscriptionBypassSnapshot> fetchForUser(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select('subscription_bypass, owner_tools_subscription_tier')
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return const SubscriptionBypassSnapshot();
      final bypass = row['subscription_bypass'] == true;
      final tierRaw = row['owner_tools_subscription_tier'] as String?;
      final tier = businessTierFromRaw(tierRaw);
      return SubscriptionBypassSnapshot(bypass: bypass, profileTier: tier);
    } catch (_) {
      return const SubscriptionBypassSnapshot();
    }
  }
}
