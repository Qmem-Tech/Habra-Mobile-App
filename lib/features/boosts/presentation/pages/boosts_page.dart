import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/business_owner_navigation_wrapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../core/widgets/notification_icon_with_badge.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../auth/domain/entities/user.dart';
import '../../../home/domain/entities/business_presence.dart';
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../../../home/presentation/pages/my_businesses_page.dart';
import '../../../home/presentation/pages/business_owner_notification_page.dart';
import '../../../home/presentation/widgets/business_owner_drawer.dart';
import '../../../explore/presentation/pages/business_detail_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../../dashboard/presentation/pages/edit_business_page.dart';
import '../../../dashboard/presentation/pages/update_hours_page.dart';
import '../../../dashboard/presentation/widgets/business_gallery_photos_dialog.dart';
import '../../../dashboard/presentation/widgets/empty_state_widget.dart';
import '../../../events/presentation/bloc/create_event_cubit.dart';
import '../../../events/presentation/pages/create_event_page.dart';
import '../../domain/entities/active_boost.dart';
import '../../domain/entities/boost_filter.dart';
import '../../domain/entities/boost_option.dart';
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
  void initState() {
    super.initState();
    // BlocListener does not run for the current home state on first subscribe;
    // kick off boosts once the first frame has a [BuildContext] with providers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final h = context.read<BusinessOwnerHomeCubit>().state;
      if (h is BusinessOwnerHomeLoaded) {
        context.read<BoostsCubit>().loadBoosts(_boostsBusinessId(h));
      }
    });
  }

  /// Same anchor as dashboard — real id even when UI shows "All businesses".
  String _boostsBusinessId(BusinessOwnerHomeState homeState) {
    if (homeState is! BusinessOwnerHomeLoaded) return '';
    return homeState.focusBusinessIdForOwnerTools ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
      listener: (context, homeState) {
        if (homeState is BusinessOwnerHomeLoaded) {
          context.read<BoostsCubit>().loadBoosts(_boostsBusinessId(homeState));
        }
      },
      builder: (context, homeState) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: BlocBuilder<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
            builder: (context, state) {
              final selected =
                  state is BusinessOwnerHomeLoaded ? state.selectedPresence : null;
              return BusinessOwnerDrawer(
                userId: widget.user.id,
                userName: widget.user.name,
                userEmail: widget.user.email,
                selectedBusiness: selected,
                showBusinessToolsMenu: state is BusinessOwnerHomeLoaded
                    ? BusinessPresence.listHasApprovedBusiness(state.presences)
                    : false,
                showDashboardMenuItem:
                    BusinessOwnerNavigationWrapper.drawerShowDashboardMenu(context),
                showBoostsMenuItem:
                    BusinessOwnerNavigationWrapper.drawerShowBoostsMenu(context),
                onHomeTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 0),
                onDashboardTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 1),
                onBoostListingTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 2),
                onEditBusinessTap: () async {
                  if (state is! BusinessOwnerHomeLoaded) return;
                  final loadedState = state;
                  final presences = loadedState.presences
                      .where((p) => p.id != 'all')
                      .toList();
                  if (presences.isEmpty) return;
                  final navContext = _scaffoldKey.currentContext;
                  if (navContext == null || !navContext.mounted) return;

                  BusinessPresence targetPresence;
                  if (presences.length == 1) {
                    targetPresence = presences.first;
                  } else {
                    final selectedId = await Navigator.push<String?>(
                      navContext,
                      MaterialPageRoute(
                        builder: (_) => MyBusinessesPage(
                          presences: presences,
                          currentPresenceId: loadedState.selectedPresenceId,
                        ),
                      ),
                    );
                    final afterPicker = _scaffoldKey.currentContext;
                    if (afterPicker == null ||
                        !afterPicker.mounted ||
                        selectedId == null) {
                      return;
                    }
                    final match = presences.where((p) => p.id == selectedId);
                    if (match.isEmpty) return;
                    targetPresence = match.first;
                  }
                  final forEdit = _scaffoldKey.currentContext;
                  if (forEdit == null || !forEdit.mounted) return;
                  final dashboardCubit = forEdit.read<DashboardCubit>();
                  Navigator.push(
                    forEdit,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider<DashboardCubit>.value(
                        value: dashboardCubit,
                        child: EditBusinessPage(business: targetPresence),
                      ),
                    ),
                  );
                },
                onViewPublicListingTap: selected != null && selected.id != 'all'
                    ? () {
                        final id = selected.id;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final nav = _scaffoldKey.currentContext;
                          if (nav == null || !nav.mounted) return;
                          Navigator.push<void>(
                            nav,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  BusinessDetailPage(businessId: id),
                            ),
                          );
                        });
                      }
                    : null,
                onBusinessPhotosTap: () async {
                  if (state is! BusinessOwnerHomeLoaded) return;
                  final loadedState = state;
                  final presences =
                      loadedState.presences.where((p) => p.id != 'all').toList();
                  if (presences.isEmpty) return;
                  final navContext = _scaffoldKey.currentContext;
                  if (navContext == null || !navContext.mounted) return;

                  BusinessPresence targetPresence;
                  if (presences.length == 1) {
                    targetPresence = presences.first;
                  } else {
                    final selectedId = await Navigator.push<String?>(
                      navContext,
                      MaterialPageRoute(
                        builder: (_) => MyBusinessesPage(
                          presences: presences,
                          currentPresenceId: loadedState.selectedPresenceId,
                        ),
                      ),
                    );
                    final afterPicker = _scaffoldKey.currentContext;
                    if (afterPicker == null ||
                        !afterPicker.mounted ||
                        selectedId == null) {
                      return;
                    }
                    final match = presences.where((p) => p.id == selectedId);
                    if (match.isEmpty) return;
                    targetPresence = match.first;
                  }
                  final dlgCtx = _scaffoldKey.currentContext;
                  if (dlgCtx == null || !dlgCtx.mounted) return;
                  final dashboardCubit = dlgCtx.read<DashboardCubit>();
                  final result = await showDialog<List<String>?>(
                    context: dlgCtx,
                    builder: (_) => BlocProvider<DashboardCubit>.value(
                      value: dashboardCubit,
                      child: BusinessGalleryPhotosDialog(
                        businessId: targetPresence.id,
                        businessName: targetPresence.displayName,
                        initialImageUrls: targetPresence.imageUrls,
                      ),
                    ),
                  );
                  if (!mounted || result == null) return;
                  final homeCtx = _scaffoldKey.currentContext;
                  if (homeCtx == null || !homeCtx.mounted) return;
                  await homeCtx.read<BusinessOwnerHomeCubit>().loadOwnerHome(
                        ownerId: widget.user.id,
                        showSetupIncomplete: false,
                      );
                },
                onUpdateHoursTap: () {
                  if (selected != null && selected.id != 'all') {
                    final dashboardCubit = context.read<DashboardCubit>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider<DashboardCubit>.value(
                          value: dashboardCubit,
                          child: UpdateHoursPage(businessId: selected.id),
                        ),
                      ),
                    );
                  }
                },
                onCreateEventTap: _navigateToCreateEvent,
                onSettingsTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              );
            },
          ),
          appBar: _buildAppBar(context),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: BlocBuilder<BoostsCubit, BoostsState>(
            builder: (context, state) {
              if (homeState is BusinessOwnerHomeError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppResources.spacingL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          homeState.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            context.read<BusinessOwnerHomeCubit>().loadOwnerHome(
                                  ownerId: widget.user.id,
                                  showSetupIncomplete: false,
                                );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (homeState is! BusinessOwnerHomeLoaded) {
                return const HabraCircularLoader(fullScreen: true);
              }

              if (state is BoostsLoading || state is BoostsInitial) {
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
                            final homeState =
                                context.read<BusinessOwnerHomeCubit>().state;
                            if (homeState is BusinessOwnerHomeLoaded) {
                              context.read<BoostsCubit>().loadBoosts(
                                    _boostsBusinessId(homeState),
                                  );
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
                return const HabraCircularLoader(fullScreen: true);
              }

              final filter = state.filter;
              final showActive =
                  (filter == BoostFilter.all || filter == BoostFilter.active) &&
                      state.hasActiveBoosts;
              final showPast =
                  (filter == BoostFilter.all || filter == BoostFilter.past) &&
                      state.hasPastBoosts;

              if (state.isEmpty || (!showActive && !showPast)) {
                return Column(
                  children: [
                    BoostFilterChips(
                      currentFilter: state.filter,
                      onFilterChanged: (f) =>
                          context.read<BoostsCubit>().setFilter(f),
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
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BoostFilterChips(
                    currentFilter: state.filter,
                    onFilterChanged: (f) =>
                        context.read<BoostsCubit>().setFilter(f),
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
                                padding: const EdgeInsets.only(
                                    bottom: AppResources.spacingM),
                                child: ActiveBoostCard(
                                  boost: boost,
                                  onTap: () =>
                                      _openActiveBoostDetails(context, boost.id),
                                  onAutoRenewChanged: (next) =>
                                      _confirmAutoRenew(context, boost, next),
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
                                padding: const EdgeInsets.only(
                                    bottom: AppResources.spacingS),
                                child: PastBoostItem(
                                  boost: boost,
                                  onReBoost: () => _openBoostOptions(
                                    context,
                                    reboostType: boost.type,
                                  ),
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
            ],
          ),
        );
      },
    );
  }

  Future<void> _navigateToCreateEvent() async {
    final dashboardCubit = context.read<DashboardCubit>();
    final homeCubit = context.read<BusinessOwnerHomeCubit>();
    final createEventCubit = di.sl<CreateEventCubit>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<DashboardCubit>.value(value: dashboardCubit),
            BlocProvider<BusinessOwnerHomeCubit>.value(value: homeCubit),
            BlocProvider<CreateEventCubit>.value(value: createEventCubit),
          ],
          child: const CreateEventPage(),
        ),
      ),
    );
    if (result == true && mounted) {
      await homeCubit.loadOwnerHome(
        ownerId: widget.user.id,
        showSetupIncomplete: false,
      );
    }
  }

  Future<void> _refreshBoostsIfPossible(BuildContext context) async {
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    if (homeState is BusinessOwnerHomeLoaded) {
      await context.read<BoostsCubit>().loadBoosts(_boostsBusinessId(homeState));
    }
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
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: GestureDetector(
              onTap: () => _openBusinessLocations(context),
              child: _buildBusinessSelector(presence),
            ),
            actions: [
              NotificationIconWithBadge(
                userId: widget.user.id,
                onOpenNotifications: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
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
    final label =
        presence != null ? presence.shortDisplayName : 'All Businesses';
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
    final state = cubit.state;
    final loaded = state is BusinessOwnerHomeLoaded ? state : null;
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => MyBusinessesPage(
          presences: loaded?.presences ?? const <BusinessPresence>[],
          currentPresenceId: loaded?.selectedPresenceId,
        ),
      ),
    );
    if (!context.mounted) return;
    if (result != null) {
      cubit.setSelectedPresenceId(result);
    }
  }

  Future<void> _openBoostOptions(
    BuildContext context, {
    BoostOptionType? reboostType,
  }) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<BoostsCubit>(),
          child: BoostOptionsPage(preselectFlowForType: reboostType),
        ),
      ),
    );
    if (!context.mounted) return;
    await _refreshBoostsIfPossible(context);
  }

  Future<void> _confirmAutoRenew(
    BuildContext context,
    ActiveBoost boost,
    bool newValue,
  ) async {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final endLabel = '${months[boost.endDate.month - 1]} ${boost.endDate.day}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newValue ? 'Turn on auto-renew?' : 'Turn off auto-renew?'),
        content: Text(
          newValue
              ? 'This boost will renew automatically on $endLabel. You can change this anytime.'
              : 'Auto-renew will stop. When this boost ends you can start a new one with Boost Now or RE-BOOST.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    try {
      await context
          .read<BoostsCubit>()
          .updateActiveBoostAutoRenew(boost.id, newValue);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue ? 'Auto-renew is on.' : 'Auto-renew is off.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update auto-renew. Please try again.'),
        ),
      );
    }
  }

  Future<void> _openActiveBoostDetails(
    BuildContext context,
    String boostId,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<BoostsCubit>(),
          child: ActiveBoostDetailsPage(boostId: boostId),
        ),
      ),
    );
    if (!context.mounted) return;
    await _refreshBoostsIfPossible(context);
  }
}
