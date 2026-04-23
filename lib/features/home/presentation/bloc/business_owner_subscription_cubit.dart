import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/business_subscription_config.dart';
import '../../../../core/services/revenue_cat_service.dart';
import '../../../../core/subscription/business_subscription_tier.dart';

class BusinessOwnerSubscriptionState extends Equatable {
  const BusinessOwnerSubscriptionState({
    this.isLoading = true,
    this.hasActiveSubscription = false,
    this.currentTier = BusinessSubscriptionTier.basic,
  });

  final bool isLoading;
  final bool hasActiveSubscription;
  final BusinessSubscriptionTier currentTier;

  bool get shouldShowSubscribeBanner =>
      BusinessSubscriptionConfig.gatesPaidBusinessTabs &&
      !isLoading &&
      !hasActiveSubscription;

  BusinessOwnerSubscriptionState copyWith({
    bool? isLoading,
    bool? hasActiveSubscription,
    BusinessSubscriptionTier? currentTier,
  }) {
    return BusinessOwnerSubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      hasActiveSubscription:
          hasActiveSubscription ?? this.hasActiveSubscription,
      currentTier: currentTier ?? this.currentTier,
    );
  }

  @override
  List<Object?> get props => [isLoading, hasActiveSubscription, currentTier];
}

/// Resolves whether business-owner paid tabs (Dash, Boosts) are allowed.
class BusinessOwnerSubscriptionCubit extends Cubit<BusinessOwnerSubscriptionState> {
  BusinessOwnerSubscriptionCubit(this._revenueCat)
      : super(const BusinessOwnerSubscriptionState());

  final RevenueCatService _revenueCat;

  Future<void> refresh(String userId) async {
    emit(state.copyWith(isLoading: true));
    final (active, tier) = await _resolveState(userId);
    emit(BusinessOwnerSubscriptionState(
      isLoading: false,
      hasActiveSubscription: active,
      currentTier: tier,
    ));
  }

  Future<(bool, BusinessSubscriptionTier)> _resolveState(String userId) async {
    switch (BusinessSubscriptionConfig.mode) {
      case BusinessOwnerSubscriptionMode.off:
        return (true, BusinessSubscriptionTier.premium);
      case BusinessOwnerSubscriptionMode.stubLocked:
        return (false, BusinessSubscriptionTier.basic);
      case BusinessOwnerSubscriptionMode.revenuecat:
        if (!_revenueCat.isInitialized) {
          return (false, BusinessSubscriptionTier.basic);
        }
        final active = await _revenueCat.hasEntitlement(
          BusinessSubscriptionConfig.revenueCatEntitlementId,
        );
        if (!active) return (false, BusinessSubscriptionTier.basic);
        final tier = await _revenueCat.resolveCurrentTier();
        return (true, tier);
      case BusinessOwnerSubscriptionMode.profile:
        return _profileSubscriptionState(userId);
    }
  }

  /// Backend sync: optional boolean on `profiles`. If the column is absent or RLS blocks
  /// the read, we default to **true** so production without a migration stays usable.
  Future<(bool, BusinessSubscriptionTier)> _profileSubscriptionState(
    String userId,
  ) async {
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('owner_tools_subscription_active, owner_tools_subscription_tier')
          .eq('id', userId)
          .maybeSingle();
      if (row is! Map<String, dynamic>) {
        return (true, BusinessSubscriptionTier.pro);
      }
      final v = row['owner_tools_subscription_active'];
      final tier =
          businessTierFromRaw(row['owner_tools_subscription_tier'] as String?);
      if (v == null) return (true, tier);
      if (v is bool) return (v, v ? tier : BusinessSubscriptionTier.basic);
      return (true, tier);
    } catch (_) {
      return (true, BusinessSubscriptionTier.pro);
    }
  }
}
