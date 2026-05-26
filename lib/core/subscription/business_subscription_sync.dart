import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/business_subscription_config.dart';
import '../constants/supabase_tables.dart';
import '../../injection/injection_container.dart' as di;
import '../services/revenue_cat_service.dart';
import 'business_subscription_tier.dart';
import 'subscription_logger.dart';

/// Writes RevenueCat subscription state to Supabase `businesses.subscription_tier`.
class BusinessSubscriptionSync {
  const BusinessSubscriptionSync._();

  static Future<void> syncOwnerTierToDatabase(
    String ownerId, {
    bool forceRefresh = false,
  }) async {
    if (BusinessSubscriptionConfig.mode !=
        BusinessOwnerSubscriptionMode.revenuecat) {
      subscriptionLog(
        'DB sync skipped — mode=${BusinessSubscriptionConfig.mode.name}',
      );
      return;
    }

    final rc = di.sl<RevenueCatService>();
    if (!rc.isInitialized) {
      subscriptionLog('DB sync skipped — RevenueCat not initialized');
      return;
    }

    try {
      final active = await rc.hasEntitlement(
        BusinessSubscriptionConfig.revenueCatEntitlementId,
        forceRefresh: forceRefresh,
      );
      final tier = active
          ? await rc.resolveCurrentTier()
          : BusinessSubscriptionTier.basic;

      subscriptionLogPlan(
        source: 'db-sync',
        userId: ownerId,
        revenueCatActive: active,
        revenueCatTier: tier,
      );

      final tierStr = active
          ? (tier == BusinessSubscriptionTier.premium ? 'premium' : 'pro')
          : 'basic';

      await Supabase.instance.client
          .from(SupabaseTables.businesses)
          .update({'subscription_tier': tierStr})
          .eq('owner_id', ownerId);

      subscriptionLog('wrote subscription_tier=$tierStr for owner=$ownerId');
    } catch (e) {
      subscriptionLog('DB sync failed: $e');
    }
  }
}
