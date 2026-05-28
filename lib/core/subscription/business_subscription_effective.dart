import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/business_subscription_config.dart';
import '../../features/home/domain/entities/business_presence.dart';
import '../../features/home/presentation/bloc/business_owner_subscription_cubit.dart';
import 'business_subscription_tier.dart';

/// Resolves the tier used for **gating** (perks, photo limits, dashboard locks).
///
/// In RevenueCat mode, a paid tier from Supabase alone is not enough — the user
/// must have an active RevenueCat entitlement. Otherwise we treat them as Basic.
class BusinessSubscriptionEffective {
  const BusinessSubscriptionEffective._();

  static BusinessSubscriptionTier resolve({
    required BusinessSubscriptionTier databaseTier,
    BusinessOwnerSubscriptionState? subscriptionState,
  }) {
    switch (BusinessSubscriptionConfig.mode) {
      case BusinessOwnerSubscriptionMode.off:
        return BusinessSubscriptionTier.premium;
      case BusinessOwnerSubscriptionMode.stubLocked:
        return BusinessSubscriptionTier.basic;
      case BusinessOwnerSubscriptionMode.revenuecat:
        final sub = subscriptionState;
        if (sub == null) {
          // Route did not pass [BusinessOwnerSubscriptionCubit]; use synced DB tier.
          return databaseTier;
        }
        if (sub.subscriptionBypass) {
          if (databaseTier != BusinessSubscriptionTier.basic) {
            return databaseTier;
          }
          return sub.currentTier != BusinessSubscriptionTier.basic
              ? sub.currentTier
              : BusinessSubscriptionTier.premium;
        }
        if (sub.isLoading || !sub.hasActiveSubscription) {
          return BusinessSubscriptionTier.basic;
        }
        return sub.currentTier;
    }
  }

  static BusinessSubscriptionTier fromContext(
    BuildContext context, {
    required BusinessSubscriptionTier databaseTier,
  }) {
    BusinessOwnerSubscriptionState? sub;
    try {
      sub = context.read<BusinessOwnerSubscriptionCubit>().state;
    } catch (_) {
      // Cubit not in tree — fall back to database only.
    }
    return resolve(databaseTier: databaseTier, subscriptionState: sub);
  }
}

extension BusinessPresenceEffectiveTier on BusinessPresence {
  BusinessSubscriptionTier effectiveTier(
    BusinessOwnerSubscriptionState? subscriptionState,
  ) =>
      BusinessSubscriptionEffective.resolve(
        databaseTier: subscriptionTier,
        subscriptionState: subscriptionState,
      );
}
