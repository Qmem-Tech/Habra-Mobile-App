import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/business_subscription_config.dart';
import '../../../../core/services/revenue_cat_service.dart';
import '../../../../core/subscription/business_subscription_tier.dart';
import '../../../../core/subscription/subscription_logger.dart';
import '../../../../core/subscription/subscription_trial_service.dart';

class BusinessOwnerSubscriptionState extends Equatable {
  const BusinessOwnerSubscriptionState({
    this.isLoading = true,
    this.hasActiveSubscription = false,
    this.currentTier = BusinessSubscriptionTier.basic,
    this.isTrialing = false,
    this.trialEndsAt,
  });

  final bool isLoading;
  final bool hasActiveSubscription;
  final BusinessSubscriptionTier currentTier;

  /// True when access is granted via platform free-trial (not a store purchase).
  final bool isTrialing;

  /// Non-null when a trial has been granted (active **or** expired).
  /// Null means the user has never started a trial.
  final DateTime? trialEndsAt;

  bool get shouldShowSubscribeBanner =>
      BusinessSubscriptionConfig.gatesPaidBusinessTabs &&
      !isLoading &&
      !hasActiveSubscription;

  BusinessOwnerSubscriptionState copyWith({
    bool? isLoading,
    bool? hasActiveSubscription,
    BusinessSubscriptionTier? currentTier,
    bool? isTrialing,
    DateTime? trialEndsAt,
    bool clearTrialEndsAt = false,
  }) {
    return BusinessOwnerSubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      hasActiveSubscription:
          hasActiveSubscription ?? this.hasActiveSubscription,
      currentTier: currentTier ?? this.currentTier,
      isTrialing: isTrialing ?? this.isTrialing,
      trialEndsAt: clearTrialEndsAt ? null : (trialEndsAt ?? this.trialEndsAt),
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, hasActiveSubscription, currentTier, isTrialing, trialEndsAt];
}

/// Resolves whether business-owner paid tabs (Dash) are allowed.
class BusinessOwnerSubscriptionCubit extends Cubit<BusinessOwnerSubscriptionState> {
  BusinessOwnerSubscriptionCubit(this._revenueCat, this._trial)
      : super(const BusinessOwnerSubscriptionState());

  final RevenueCatService _revenueCat;
  final SubscriptionTrialService _trial;

  Future<void> refresh(String userId, {bool forceRefresh = false}) async {
    emit(state.copyWith(isLoading: true));
    final result = await _resolveState(userId, forceRefresh: forceRefresh);
    subscriptionLogPlan(
      source: 'cubit',
      userId: userId,
      revenueCatActive: result.active,
      revenueCatTier: result.tier,
    );
    subscriptionLog(
      'gating mode=${BusinessSubscriptionConfig.mode.name} '
      'isTrialing=${result.isTrialing}',
    );
    emit(BusinessOwnerSubscriptionState(
      isLoading: false,
      hasActiveSubscription: result.active,
      currentTier: result.tier,
      isTrialing: result.isTrialing,
      trialEndsAt: result.trialEndsAt,
    ));
  }

  Future<
      ({
        bool active,
        BusinessSubscriptionTier tier,
        bool isTrialing,
        DateTime? trialEndsAt,
      })> _resolveState(String userId, {bool forceRefresh = false}) async {
    switch (BusinessSubscriptionConfig.mode) {
      case BusinessOwnerSubscriptionMode.off:
        return (
          active: true,
          tier: BusinessSubscriptionTier.premium,
          isTrialing: false,
          trialEndsAt: null,
        );
      case BusinessOwnerSubscriptionMode.stubLocked:
        return (
          active: false,
          tier: BusinessSubscriptionTier.basic,
          isTrialing: false,
          trialEndsAt: null,
        );
      case BusinessOwnerSubscriptionMode.revenuecat:
        // Check platform trial first (independent of store / RC).
        final trialStatus = await _trial.getTrialStatus(userId);

        if (trialStatus.isActive) {
          return (
            active: true,
            tier: BusinessSubscriptionTier.pro,
            isTrialing: true,
            trialEndsAt: trialStatus.endsAt,
          );
        }

        // Fall through to RevenueCat store subscription.
        if (!_revenueCat.isInitialized) {
          return (
            active: false,
            tier: BusinessSubscriptionTier.basic,
            isTrialing: false,
            trialEndsAt: trialStatus.endsAt,
          );
        }

        final active = await _revenueCat.hasEntitlement(
          BusinessSubscriptionConfig.revenueCatEntitlementId,
          forceRefresh: forceRefresh,
        );
        if (!active) {
          return (
            active: false,
            tier: BusinessSubscriptionTier.basic,
            isTrialing: false,
            trialEndsAt: trialStatus.endsAt,
          );
        }
        final tier = await _revenueCat.resolveCurrentTier();
        return (
          active: true,
          tier: tier,
          isTrialing: false,
          trialEndsAt: trialStatus.endsAt,
        );
    }
  }
}
