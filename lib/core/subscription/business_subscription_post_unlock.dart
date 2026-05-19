import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../features/home/presentation/bloc/business_owner_home_cubit.dart';
import '../../features/home/presentation/bloc/business_owner_home_state.dart';
import '../../features/home/presentation/bloc/business_owner_subscription_cubit.dart';
import '../navigation/business_owner_navigation_wrapper.dart';
import 'business_subscription_sync.dart';
import 'subscription_logger.dart';

/// Refreshes owner UI after subscribe, restore, or tier change.
class BusinessSubscriptionPostUnlock {
  const BusinessSubscriptionPostUnlock._();

  /// Retries RC refresh until entitlement is active (sandbox can lag).
  static Future<bool> refreshSubscriptionUntilActive(
    BusinessOwnerSubscriptionCubit cubit,
    String userId, {
    int maxAttempts = 4,
    Duration delay = const Duration(seconds: 2),
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      await cubit.refresh(userId, forceRefresh: true);
      if (cubit.state.hasActiveSubscription) {
        subscriptionLog('subscription active after attempt $attempt');
        return true;
      }
      if (attempt < maxAttempts) {
        await Future.delayed(delay);
      }
    }
    subscriptionLog('subscription still inactive after $maxAttempts attempts');
    return false;
  }

  /// Sync Supabase, reload home/dashboard, and refresh nav tool gates.
  static Future<void> apply(
    BuildContext context, {
    required String userId,
    bool forceRefreshRevenueCat = false,
  }) async {
    await BusinessSubscriptionSync.syncOwnerTierToDatabase(
      userId,
      forceRefresh: forceRefreshRevenueCat,
    );
    if (!context.mounted) return;

    final subCubit = context.read<BusinessOwnerSubscriptionCubit>();
    await subCubit.refresh(userId, forceRefresh: forceRefreshRevenueCat);
    if (!context.mounted) return;

    await context.read<BusinessOwnerHomeCubit>().loadOwnerHome(
          ownerId: userId,
          showSetupIncomplete: false,
        );
    if (!context.mounted) return;

    try {
      final homeState = context.read<BusinessOwnerHomeCubit>().state;
      if (homeState is BusinessOwnerHomeLoaded) {
        final businessId = homeState.focusBusinessIdForOwnerTools;
        if (businessId != null) {
          await context.read<DashboardCubit>().loadDashboard(
                businessId,
                ownerId: userId,
              );
        }
      }
    } catch (_) {
      // Dashboard cubit may not be in tree.
    }

    if (!context.mounted) return;
    BusinessOwnerNavigationWrapper.invalidateBusinessToolsAccessCache(context);
    subscriptionLog('post-unlock refresh complete — userId=$userId');
  }
}
