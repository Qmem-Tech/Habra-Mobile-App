import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/business_subscription_config.dart';
import '../../../../core/services/revenue_cat_service.dart';

class BusinessOwnerSubscriptionState extends Equatable {
  const BusinessOwnerSubscriptionState({
    this.isLoading = true,
    this.hasActiveSubscription = false,
  });

  final bool isLoading;
  final bool hasActiveSubscription;

  bool get shouldShowSubscribeBanner =>
      BusinessSubscriptionConfig.gatesPaidBusinessTabs &&
      !isLoading &&
      !hasActiveSubscription;

  BusinessOwnerSubscriptionState copyWith({
    bool? isLoading,
    bool? hasActiveSubscription,
  }) {
    return BusinessOwnerSubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      hasActiveSubscription:
          hasActiveSubscription ?? this.hasActiveSubscription,
    );
  }

  @override
  List<Object?> get props => [isLoading, hasActiveSubscription];
}

/// Resolves whether business-owner paid tabs (Dash, Boosts) are allowed.
class BusinessOwnerSubscriptionCubit extends Cubit<BusinessOwnerSubscriptionState> {
  BusinessOwnerSubscriptionCubit(this._revenueCat)
      : super(const BusinessOwnerSubscriptionState());

  final RevenueCatService _revenueCat;

  Future<void> refresh(String userId) async {
    emit(state.copyWith(isLoading: true));
    final active = await _resolveActive(userId);
    emit(BusinessOwnerSubscriptionState(
      isLoading: false,
      hasActiveSubscription: active,
    ));
  }

  Future<bool> _resolveActive(String userId) async {
    switch (BusinessSubscriptionConfig.mode) {
      case BusinessOwnerSubscriptionMode.off:
        return true;
      case BusinessOwnerSubscriptionMode.stubLocked:
        return false;
      case BusinessOwnerSubscriptionMode.revenuecat:
        if (!_revenueCat.isInitialized) {
          return false;
        }
        return await _revenueCat.hasEntitlement(
          BusinessSubscriptionConfig.revenueCatEntitlementId,
        );
      case BusinessOwnerSubscriptionMode.profile:
        return _profileSubscriptionActive(userId);
    }
  }

  /// Backend sync: optional boolean on `profiles`. If the column is absent or RLS blocks
  /// the read, we default to **true** so production without a migration stays usable.
  Future<bool> _profileSubscriptionActive(String userId) async {
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('owner_tools_subscription_active')
          .eq('id', userId)
          .maybeSingle();
      if (row is! Map<String, dynamic>) return true;
      final v = row['owner_tools_subscription_active'];
      if (v == null) return true;
      if (v is bool) return v;
      return true;
    } catch (_) {
      return true;
    }
  }
}
