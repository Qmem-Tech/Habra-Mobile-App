import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../home/domain/entities/business_presence.dart';
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../../../home/presentation/pages/business_locations_page.dart';
import '../../../home/presentation/pages/business_owner_notification_page.dart';
import '../../../home/presentation/widgets/business_owner_drawer.dart';
import '../../../dashboard/presentation/widgets/empty_state_widget.dart';
import '../bloc/boosts_cubit.dart';
import '../bloc/boosts_state.dart';
import '../widgets/active_boost_card.dart';
import '../widgets/boost_filter_chips.dart';
import '../widgets/past_boost_item.dart';
import 'boost_options_page.dart';
import 'active_boost_details_page.dart';

/// Main Boosts tab page: filters, active/past boosts list, empty state, Boost Now CTA.
class BoostsPage extends StatefulWidget {
  const BoostsPage({super.key, required this.user});

  final User user;

  @override
  State<BoostsPage> createState() => _BoostsPageState();
}

class _BoostsPageState extends State<BoostsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
      listener: (context, homeState) {
        if (homeState is BusinessOwnerHomeLoaded &&
            homeState.selectedPresence != null &&
            homeState.selectedPresence!.id != 'all') {
          context.read<BoostsCubit>().loadBoosts(homeState.selectedPresence!.id);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: BlocBuilder<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
          builder: (context, state) {
            final selected = state is BusinessOwnerHomeLoaded ? state.selectedPresence : null;
            return BusinessOwnerDrawer(
              userId: widget.user.id,
              userName: widget.user.name,
              userEmail: widget.user.email,
              selectedBusiness: selected,
            );
          },
        ),
        appBar: _buildAppBar(context),
        body: BlocConsumer<BoostsCubit, BoostsState>(
          listener: (context, state) {
            if (state is! BoostsLoaded && state is! BoostsLoading && state is! BoostsInitial) {
              final homeState = context.read<BusinessOwnerHomeCubit>().state;
              if (homeState is BusinessOwnerHomeLoaded &&
                  homeState.selectedPresence != null &&
                  homeState.selectedPresence!.id != 'all') {
                context.read<BoostsCubit>().loadBoosts(homeState.selectedPresence!.id);
              }
            }
          },
          child: BlocBuilder<BoostsCubit, BoostsState>(
            builder: (context, state) {
              if (state is BoostsLoading || state is BoostsInitial) {
                if (state is BoostsInitial) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final homeState = context.read<BusinessOwnerHomeCubit>().state;
                    if (homeState is BusinessOwnerHomeLoaded &&
                        homeState.selectedPresence != null &&
                        homeState.selectedPresence!.id != 'all') {
                      context.read<BoostsCubit>().loadBoosts(homeState.selectedPresence!.id);
                    }
                  });
                }
                return const HabraCircularLoader(fullScreen: true);
              }
              if (state is BoostsError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppResources.spacingL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            final homeState = context.read<BusinessOwnerHomeCubit>().state;
                            if (homeState is BusinessOwnerHomeLoaded &&
                                homeState.selectedPresence != null) {
                              context.read<BoostsCubit>().loadBoosts(homeState.selectedPresence!.id);
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (state is! BoostsLoaded) {
                return const SizedBox.shrink();
              }

              final filter = state.filter;
              final showActive = (filter == BoostFilter.all || filter == BoostFilter.active) && state.hasActiveBoosts;
              final showPast = (filter == BoostFilter.all || filter == BoostFilter.past) && state.hasPastBoosts;

              if (state.isEmpty || (!showActive && !showPast)) {
                return Column(
                  children: [
                    BoostFilterChips(
                      currentFilter: state.filter,
                      onFilterChanged: (f) => context.read<BoostsCubit>().setFilter(f),
                    ),
                    Expanded(
                      child: EmptyStateWidget(
                        illustrationPath: AppAssets.boostsEmptyState,
                        title: 'No Boost used',
                        description: 'Boost your business Now',
                        actionLabel: 'Boost Now',
                        onAction: () => _openBoostOptions(context),
                      ),
                    ),
                    _buildBoostNowButton(context),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BoostFilterChips(
                    currentFilter: state.filter,
                    onFilterChanged: (f) => context.read<BoostsCubit>().setFilter(f),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showActive) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppResources.spacingM,
                                AppResources.spacingS,
                                AppResources.spacingM,
                                AppResources.spacingS,
                              ),
                              child: Text(
                                'Active Now',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            ...state.displayedActive.map(
                              (boost) => Padding(
                                padding: const EdgeInsets.only(bottom: AppResources.spacingM),
                                child: ActiveBoostCard(
                                  boost: boost,
                                  onTap: () => _openActiveBoostDetails(context, boost.id),
                                ),
                              ),
                            ),
                          ],
                          if (showPast) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppResources.spacingM,
                                AppResources.spacingM,
                                AppResources.spacingM,
                                AppResources.spacingS,
                              ),
                              child: Text(
                                'Past Boosts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            ...state.displayedPast.map(
                              (boost) => Padding(
                                padding: const EdgeInsets.only(bottom: AppResources.spacingS),
                                child: PastBoostItem(
                                  boost: boost,
                                  onReBoost: () => _openBoostOptions(context),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _buildBoostNowButton(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: BlocBuilder<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
        builder: (context, state) {
          final presence = state is BusinessOwnerHomeLoaded ? state.selectedPresence : null;
          return AppBar(
            backgroundColor: AppColors.backgroundWhite,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: GestureDetector(
              onTap: () => _openBusinessLocations(context),
              child: _buildBusinessSelector(presence),
            ),
            actions: [
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BusinessOwnerNotificationPage(userId: widget.user.id),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBusinessSelector(BusinessPresence? presence) {
    final label = presence != null
        ? '${presence.shortDisplayName}'
        : 'All Businesses';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.business, size: 18, color: AppColors.brandPrimary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.brandPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.brandPrimary),
        ],
      ),
    );
  }

  Widget _buildBoostNowButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppResources.spacingM),
      child: AppButton(
        text: 'Boost Now',
        icon: Icons.rocket_launch,
        onPressed: () => _openBoostOptions(context),
      ),
    );
  }

  Future<void> _openBusinessLocations(BuildContext context) async {
    final cubit = context.read<BusinessOwnerHomeCubit>();
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessLocationsPage(
          currentPresenceId: (cubit.state is BusinessOwnerHomeLoaded)
              ? (cubit.state as BusinessOwnerHomeLoaded).selectedPresenceId
              : null,
        ),
      ),
    );
    if (!context.mounted) return;
    if (result != null) {
      cubit.setSelectedPresenceId(result);
    }
  }

  void _openBoostOptions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<BoostsCubit>(),
          child: const BoostOptionsPage(),
        ),
      ),
    );
  }

  void _openActiveBoostDetails(BuildContext context, String boostId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<BoostsCubit>(),
          child: ActiveBoostDetailsPage(boostId: boostId),
        ),
      ),
    );
  }
}
