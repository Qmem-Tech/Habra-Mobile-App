import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/business_owner_navigation_wrapper.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/subscription/business_subscription_policy.dart';
import '../../../../core/subscription/business_subscription_tier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../../domain/entities/boost_option.dart';
import '../bloc/boosts_cubit.dart';
import '../bloc/boosts_state.dart';
import '../widgets/boost_flow_status_body.dart';
import '../widgets/boost_option_card.dart';
import 'select_location_page.dart';
import 'select_deal_to_boost_page.dart';
import 'select_job_to_boost_page.dart';

/// "What would you like to boost?" – Business Listing, Deal, or Job.
///
/// When [preselectFlowForType] is set (e.g. from RE-BOOST), the matching option
/// flow opens automatically after options load.
class BoostOptionsPage extends StatefulWidget {
  const BoostOptionsPage({
    super.key,
    required this.user,
    this.preselectFlowForType,
  });

  final User user;
  final BoostOptionType? preselectFlowForType;

  @override
  State<BoostOptionsPage> createState() => _BoostOptionsPageState();
}

class _BoostOptionsPageState extends State<BoostOptionsPage> {
  bool _didAutoOpenReboostFlow = false;

  @override
  void initState() {
    super.initState();
    context.read<BoostsCubit>().loadBoostOptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Boost Options',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<BoostsCubit, BoostsState>(
        listenWhen: (prev, curr) =>
            !_didAutoOpenReboostFlow &&
            widget.preselectFlowForType != null &&
            curr is BoostOptionsLoaded,
        listener: (context, state) {
          if (state is! BoostOptionsLoaded) return;
          final want = widget.preselectFlowForType!;
          BoostOption? match;
          for (final o in state.options) {
            if (o.type == want) {
              match = o;
              break;
            }
          }
          _didAutoOpenReboostFlow = true;
          if (match == null) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final homeState = context.read<BusinessOwnerHomeCubit>().state;
            final tier = _subscriptionTierForBoost(homeState);
            if ((want == BoostOptionType.deal || want == BoostOptionType.job) &&
                !BusinessSubscriptionPolicy.canBoostDealsOrJobs(tier)) {
              BusinessOwnerNavigationWrapper.openBusinessOwnerSubscription(
                context,
                widget.user,
              );
              return;
            }
            _onOptionTap(context, match!);
          });
        },
        builder: (context, state) {
          if (state is BoostsError) {
            return BoostFlowErrorBody(
              message: state.message,
              onRetry: () => context.read<BoostsCubit>().loadBoostOptions(),
              onBack: () => Navigator.pop(context),
            );
          }
          if (state is! BoostOptionsLoaded) {
            return const HabraCircularLoader(fullScreen: true);
          }
          final options = state.options;
          final homeState = context.watch<BusinessOwnerHomeCubit>().state;
          final tier = _subscriptionTierForBoost(homeState);
          final canDealJobBoost =
              BusinessSubscriptionPolicy.canBoostDealsOrJobs(tier);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppResources.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What would you like to boost?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppResources.spacingL),
                ...options.map(
                  (option) {
                    final locked = !canDealJobBoost &&
                        (option.type == BoostOptionType.deal ||
                            option.type == BoostOptionType.job);
                    return BoostOptionCard(
                      option: option,
                      locked: locked,
                      onTap: () => _onOptionTap(context, option),
                    );
                  },
                ),
                const SizedBox(height: AppResources.spacingL),
                _buildProTip(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProTip() {
    return Container(
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppResources.radiusL),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: AppColors.brandPrimary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pro Tip',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Boosting increases your visibility among the local Habesha community. Most owners start with Business Listing.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BusinessSubscriptionTier _subscriptionTierForBoost(
    BusinessOwnerHomeState homeState,
  ) {
    if (homeState is! BusinessOwnerHomeLoaded) {
      return BusinessSubscriptionTier.basic;
    }
    final bid = homeState.focusBusinessIdForOwnerTools;
    if (bid == null) return BusinessSubscriptionTier.basic;
    for (final p in homeState.presences) {
      if (p.id == bid) return p.subscriptionTier;
    }
    return BusinessSubscriptionTier.basic;
  }

  void _onOptionTap(BuildContext context, BoostOption option) {
    final tier = _subscriptionTierForBoost(
      context.read<BusinessOwnerHomeCubit>().state,
    );
    if ((option.type == BoostOptionType.deal ||
            option.type == BoostOptionType.job) &&
        !BusinessSubscriptionPolicy.canBoostDealsOrJobs(tier)) {
      BusinessOwnerNavigationWrapper.openBusinessOwnerSubscription(
        context,
        widget.user,
      );
      return;
    }

    switch (option.type) {
      case BoostOptionType.businessListing:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<BoostsCubit>(),
              child: const SelectLocationPage(),
            ),
          ),
        );
        break;
      case BoostOptionType.deal:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<BoostsCubit>(),
              child: const SelectDealToBoostPage(),
            ),
          ),
        );
        break;
      case BoostOptionType.job:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<BoostsCubit>(),
              child: const SelectJobToBoostPage(),
            ),
          ),
        );
        break;
    }
  }
}
