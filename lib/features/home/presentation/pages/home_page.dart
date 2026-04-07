import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/location/location_access_messages.dart';
import '../../../../core/location/profile_home_city_sync.dart';
import '../../../../core/location/session_device_location_cubit.dart';
import '../../../../core/location/user_geo_for_feed.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../core/navigation/main_navigation_wrapper.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/home_feed_location.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/job.dart';
import '../bloc/home_cubit.dart';
import '../bloc/home_state.dart';
import '../widgets/event_card.dart';
import '../widgets/deal_card.dart';
import '../widgets/business_card.dart';
import '../widgets/job_card.dart';
import 'search_page.dart';
import 'location_selection_page.dart';
import '../../../jobs/presentation/pages/job_detail_page.dart';
import '../../../explore/presentation/pages/business_detail_page.dart';
import '../../../explore/presentation/pages/deal_detail_page.dart';
import '../../../explore/presentation/pages/deals_page.dart';
import '../../../explore/presentation/pages/directory_page.dart';
import '../../../events/presentation/pages/event_detail_page.dart';
import '../../../../core/navigation/main_nav_scope.dart';
import '../../../../core/widgets/notification_icon_with_badge.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final String userName;
  final LocationEntity? currentLocation;

  /// When true, location comes from [SessionDeviceLocationCubit] (ephemeral GPS / session picks).
  final bool useSessionDeviceLocation;

  const HomePage({
    super.key,
    required this.userId,
    required this.userName,
    this.currentLocation,
    this.useSessionDeviceLocation = false,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LocationEntity? _currentLocation;

  static const LocationEntity _fallbackMetro = LocationEntity(
    id: 'default',
    city: 'Washington',
    state: 'D.C.',
    country: 'USA',
  );

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.currentLocation ?? _fallbackMetro;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadHomeData();
    });
  }

  String _displayFirstName() {
    final raw = widget.userName.trim();
    if (raw.isEmpty) return 'there';
    final first = raw.split(RegExp(r'\s+')).first;
    return first.isEmpty ? 'there' : first;
  }

  String _locationQueryString(BuildContext context) {
    if (widget.useSessionDeviceLocation) {
      return SessionDeviceLocationCubit.labelOrFallback(
        context.read<SessionDeviceLocationCubit>().state,
      );
    }
    return _currentLocation?.fullDisplayName ?? 'Washington, D.C.';
  }

  String _locationChipLabel(BuildContext context) {
    if (widget.useSessionDeviceLocation) {
      final s = context.watch<SessionDeviceLocationCubit>().state;
      if (s is SessionDeviceLocationLoading) return 'Locating…';
      if (s is SessionDeviceLocationReady) return s.location.fullDisplayName;
      if (s is SessionDeviceLocationFailure) return 'Location unavailable';
      return 'Washington, D.C.';
    }
    return _currentLocation?.fullDisplayName ?? 'Washington, D.C.';
  }

  String _emptyStateCityLabel(BuildContext context) {
    if (widget.useSessionDeviceLocation) {
      final s = context.read<SessionDeviceLocationCubit>().state;
      if (s is SessionDeviceLocationReady) return s.location.city;
      return 'your area';
    }
    return _currentLocation?.city ?? 'your location';
  }

  HomeFeedLocation _homeFeedLocation(BuildContext context) {
    final label = _locationQueryString(context);
    LocationEntity? anchor;
    if (widget.useSessionDeviceLocation) {
      final s = context.read<SessionDeviceLocationCubit>().state;
      if (s is SessionDeviceLocationReady) anchor = s.location;
    } else {
      anchor = _currentLocation;
    }
    final lat = anchor?.latitude;
    final lng = anchor?.longitude;
    final geo = (lat != null && lng != null)
        ? UserGeoForFeed(latitude: lat, longitude: lng)
        : null;
    return HomeFeedLocation(label: label, geo: geo);
  }

  void _loadHomeData() {
    if (!mounted) return;
    context.read<HomeCubit>().loadHomeData(_homeFeedLocation(context));
  }

  Future<void> _onLocationChipTapped() async {
    if (widget.useSessionDeviceLocation) {
      final cubit = context.read<SessionDeviceLocationCubit>();
      final s = cubit.state;
      if (s is SessionDeviceLocationLoading) return;
      if (s is SessionDeviceLocationFailure) {
        await cubit.refreshFromDeviceGps();
        if (!mounted) return;
        final next = cubit.state;
        if (next is SessionDeviceLocationFailure) {
          LocationAccessMessages.showFailureSnackBar(
            context,
            message: next.message,
          );
        }
        return;
      }
    }
    await _navigateToLocationSelection();
  }

  bool _hasSectionIssues(HomeLoaded s) {
    return s.eventsError != null ||
        s.dealsError != null ||
        s.businessesError != null ||
        s.jobsError != null;
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeError) {
              return _buildErrorView(state.message);
            }

            if (state is HomeInitial || state is HomeLoading) {
              return const HabraCircularLoader(fullScreen: true);
            }

            if (state is HomeLoaded) {
              return _buildLoadedScrollView(state);
            }

            return const HabraCircularLoader(fullScreen: true);
          },
        ),
      ),
    );

    if (!widget.useSessionDeviceLocation) {
      return scaffold;
    }

    return BlocListener<SessionDeviceLocationCubit, SessionDeviceLocationState>(
      listenWhen: (prev, curr) =>
          curr is SessionDeviceLocationReady ||
          curr is SessionDeviceLocationFailure,
      listener: (context, state) {
        if (state is SessionDeviceLocationReady) {
          _loadHomeData();
        } else if (state is SessionDeviceLocationFailure) {
          LocationAccessMessages.showFailureSnackBar(
            context,
            message: state.message,
          );
        }
      },
      child: scaffold,
    );
  }

  Widget _buildLoadedScrollView(HomeLoaded state) {
    final allEmpty = state.events.isEmpty &&
        state.deals.isEmpty &&
        state.businesses.isEmpty &&
        state.jobs.isEmpty;
    final fullyQuiet = allEmpty && !_hasSectionIssues(state);

    return RefreshIndicator(
      color: AppColors.customerHomePrimary,
      onRefresh: () =>
          context.read<HomeCubit>().loadHomeData(_homeFeedLocation(context)),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(),
          _buildGreetingSection(),
          _buildSearchSection(),
          if (_hasSectionIssues(state)) _buildIssuesBanner(state),
          if (fullyQuiet)
            SliverToBoxAdapter(child: _buildRegionalEmptyCard())
          else ...[
            _buildEventsSection(state.events, state.eventsError),
            _buildDealsSection(state.deals, state.dealsError),
            _buildBusinessesSection(state.businesses, state.businessesError),
            _buildJobsSection(state.jobs, state.jobsError),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildIssuesBanner(HomeLoaded state) {
    final lines = <String>[];
    if (state.eventsError != null) {
      lines.add('Events: ${state.eventsError!}');
    }
    if (state.dealsError != null) {
      lines.add('Deals: ${state.dealsError!}');
    }
    if (state.businessesError != null) {
      lines.add('Businesses: ${state.businessesError!}');
    }
    if (state.jobsError != null) {
      lines.add('Jobs: ${state.jobsError!}');
    }
    if (lines.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Material(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lines.join('\n'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadHomeData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionalEmptyCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            "It's quiet in ${_emptyStateCityLabel(context)}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "We haven't found any Habesha businesses or events here yet. The community is growing, but this spot is still untouched.",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loadHomeData,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.customerHomePrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: AppColors.backgroundWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.textPrimary, size: 26),
        onPressed: () {
          MainNavScope.maybeOf(context)?.scaffoldKey.currentState?.openDrawer();
        },
      ),
      centerTitle: true,
      title: GestureDetector(
        onTap: _onLocationChipTapped,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.customerLocationPillBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: AppColors.customerHomePrimary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _locationChipLabel(context),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.customerHomePrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.customerHomePrimary,
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Material(
            color: AppColors.backgroundLight,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: NotificationIconWithBadge(
              userId: MainNavScope.maybeOf(context)?.userId,
              iconColor: AppColors.textPrimary,
              onOpenNotifications: () async {
                final scope = MainNavScope.maybeOf(context);
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => NotificationPage(userId: scope?.userId),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Text(
          'Selam, ${_displayFirstName()}! 👋',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.8,
            height: 1.15,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: GestureDetector(
          onTap: () async {
            await Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SearchPage(
                  location: _locationQueryString(context),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.backgroundGrey.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppColors.textTertiary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  'Find business, event...',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitleRow({
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.customerHomePrimary,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionMessage({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.backgroundGrey.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection(List<Event> events, String? error) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitleRow(
            title: 'Happening This Week',
            actionLabel: 'View All >',
            onAction: () {
              MainNavigationWrapper.navigateToTab(context, 1);
            },
          ),
          if (error != null)
            _sectionMessage(
              icon: Icons.wifi_off_outlined,
              title: "Couldn't load events",
              subtitle: error,
            )
          else if (events.isEmpty)
            _sectionMessage(
              icon: Icons.event_outlined,
              title: 'No events this week',
              subtitle: 'Check back soon for concerts, gatherings, and more near you.',
            )
          else
            SizedBox(
              height: 320,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return EventCard(
                    event: event,
                    onTap: () async {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => EventDetailPage(eventId: event.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDealsSection(List<Deal> deals, String? error) {
    final topDeals = deals.take(4).toList();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitleRow(
            title: 'Hot Deals Near You',
            actionLabel: 'View All >',
            onAction: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(builder: (_) => const DealsPage()),
              );
            },
          ),
          if (error != null)
            _sectionMessage(
              icon: Icons.wifi_off_outlined,
              title: "Couldn't load deals",
              subtitle: error,
            )
          else if (topDeals.isEmpty)
            _sectionMessage(
              icon: Icons.local_offer_outlined,
              title: 'No deals right now',
              subtitle: 'Nearby specials will show up here when businesses post them.',
            )
          else
            SizedBox(
              height: 124,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: topDeals.length,
                itemBuilder: (context, index) {
                  final deal = topDeals[index];
                  return DealCard(
                    deal: deal,
                    onTap: () async {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => DealDetailPage(dealId: deal.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessesSection(List<Business> businesses, String? error) {
    final topBusinesses = businesses.take(4).toList();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitleRow(
            title: 'Popular Businesses',
            actionLabel: 'View All >',
            onAction: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(builder: (_) => const DirectoryPage()),
              );
            },
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _sectionMessage(
                icon: Icons.wifi_off_outlined,
                title: "Couldn't load businesses",
                subtitle: error,
              ),
            )
          else if (topBusinesses.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _sectionMessage(
                icon: Icons.storefront_outlined,
                title: 'No businesses to show',
                subtitle: 'Try another area or check back as more places join Habra.',
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topBusinesses.length,
                itemBuilder: (context, index) {
                  final b = topBusinesses[index];
                  return BusinessCard(
                    business: b,
                    onTap: () async {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => BusinessDetailPage(businessId: b.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJobsSection(List<Job> jobs, String? error) {
    final topJobs = jobs.take(4).toList();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitleRow(
            title: 'Latest Jobs',
            actionLabel: 'View All >',
            onAction: () {
              MainNavigationWrapper.navigateToTab(context, 3);
            },
          ),
          if (error != null)
            _sectionMessage(
              icon: Icons.wifi_off_outlined,
              title: "Couldn't load jobs",
              subtitle: error,
            )
          else if (topJobs.isEmpty)
            _sectionMessage(
              icon: Icons.work_outline,
              title: 'No jobs available at the moment',
              subtitle: 'New roles from local businesses will appear here.',
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topJobs.length,
                itemBuilder: (context, index) {
                  final job = topJobs[index];
                  return JobCard(
                    job: job,
                    onTap: () async {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => JobDetailPage(jobId: job.id),
                        ),
                      );
                    },
                    onApply: () async {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => JobDetailPage(jobId: job.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    final safeMessage = message.trim().isEmpty
        ? 'Something went wrong. Please try again.'
        : message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Could not load your feed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              safeMessage,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loadHomeData,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.customerHomePrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToLocationSelection() async {
    final result = await Navigator.push<LocationEntity>(
      context,
      MaterialPageRoute(builder: (_) => const LocationSelectionPage()),
    );
    if (result == null) return;
    if (!mounted) return;
    if (widget.useSessionDeviceLocation) {
      context.read<SessionDeviceLocationCubit>().setSessionLocation(result);
      await persistProfileHomeCityIfSignedIn(context, result);
    } else {
      setState(() {
        _currentLocation = result;
      });
    }
    _loadHomeData();
  }
}
