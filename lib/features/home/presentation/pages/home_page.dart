import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/location/location_access_messages.dart';
import '../../../../core/location/session_device_location_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../core/navigation/main_navigation_wrapper.dart';
import '../../domain/entities/location_entity.dart';
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

enum _RecommendationFilter { all, businesses, events, deals }

class _HomePageState extends State<HomePage> {
  LocationEntity? _currentLocation;
  _RecommendationFilter _recommendationFilter = _RecommendationFilter.all;

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

  void _loadHomeData() {
    if (!mounted) return;
    context.read<HomeCubit>().loadHomeData(_locationQueryString(context));
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

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeError) {
              return _buildErrorView(state.message);
            }

            if (state is HomeLoading) {
              return const HabraCircularLoader(fullScreen: true);
            }

            if (state is HomeLoaded && state.events.isEmpty &&
                state.deals.isEmpty && state.businesses.isEmpty &&
                state.jobs.isEmpty) {
              return _buildEmptyState();
            }

            return _buildContent(state);
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

  Widget _buildContent(HomeState state) {
    final events = state is HomeLoaded ? state.events : <Event>[];
    final deals = state is HomeLoaded ? state.deals : <Deal>[];
    final businesses = state is HomeLoaded ? state.businesses : <Business>[];
    final jobs = state is HomeLoaded ? state.jobs : <Job>[];

    final hasRecommendations = events.isNotEmpty || deals.isNotEmpty || businesses.isNotEmpty;

    return CustomScrollView(
      slivers: [
        _buildHeader(),
        _buildGreetingSection(),
        _buildSearchSection(),
        if (hasRecommendations) _buildRecommendationsSection(events, deals, businesses),
        if (events.isNotEmpty) _buildEventsSection(events),
        if (deals.isNotEmpty) _buildDealsSection(deals),
        if (businesses.isNotEmpty) _buildBusinessesSection(businesses),
        if (jobs.isNotEmpty) _buildJobsSection(jobs),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
        onPressed: () {
          MainNavScope.maybeOf(context)?.scaffoldKey.currentState?.openDrawer();
        },
      ),
      centerTitle: false,
      title: GestureDetector(
        onTap: _onLocationChipTapped,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _locationChipLabel(context),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
      actions: [
        NotificationIconWithBadge(
          userId: MainNavScope.maybeOf(context)?.userId,
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
      ],
    );
  }

  Widget _buildGreetingSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Selam, ${widget.userName}! 👋',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(
    List<Event> events,
    List<Deal> deals,
    List<Business> businesses,
  ) {
    final filteredEvents = _recommendationFilter == _RecommendationFilter.all ||
            _recommendationFilter == _RecommendationFilter.events
        ? events
        : <Event>[];
    final filteredDeals = _recommendationFilter == _RecommendationFilter.all ||
            _recommendationFilter == _RecommendationFilter.deals
        ? deals
        : <Deal>[];
    final filteredBusinesses = _recommendationFilter == _RecommendationFilter.all ||
            _recommendationFilter == _RecommendationFilter.businesses
        ? businesses
        : <Business>[];

    final totalCount =
        filteredEvents.length + filteredDeals.length + filteredBusinesses.length;
    if (totalCount == 0) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            child: Row(
              children: [
                // const Icon(Icons.auto_awesome, color: AppColors.brandSecondary, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Recommended for you',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _RecommendationChip(
                    label: 'All',
                    selected: _recommendationFilter == _RecommendationFilter.all,
                    onTap: () =>
                        setState(() => _recommendationFilter = _RecommendationFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _RecommendationChip(
                    label: 'Businesses',
                    selected: _recommendationFilter == _RecommendationFilter.businesses,
                    onTap: () => setState(
                        () => _recommendationFilter = _RecommendationFilter.businesses),
                  ),
                  const SizedBox(width: 8),
                  _RecommendationChip(
                    label: 'Events',
                    selected: _recommendationFilter == _RecommendationFilter.events,
                    onTap: () =>
                        setState(() => _recommendationFilter = _RecommendationFilter.events),
                  ),
                  const SizedBox(width: 8),
                  _RecommendationChip(
                    label: 'Deals',
                    selected: _recommendationFilter == _RecommendationFilter.deals,
                    onTap: () =>
                        setState(() => _recommendationFilter = _RecommendationFilter.deals),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ...filteredBusinesses.take(5).map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _RecommendationBusinessCard(business: b),
                      ),
                    ),
                ...filteredEvents.take(5).map(
                      (e) => EventCard(event: e),
                    ),
                ...filteredDeals.take(5).map(
                      (d) => DealCard(deal: d),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchPage()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.backgroundGrey.withValues(alpha:0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.textSecondary.withValues(alpha:0.7), size: 20),
                const SizedBox(width: 12),
                Text(
                  'Find business, event...',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
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

  Widget _buildEventsSection(List<Event> events) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Happening This Week',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to Events tab in the main navigation
                    MainNavigationWrapper.navigateToTab(context, 1);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All >',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return EventCard(
                  event: event,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
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

  Widget _buildDealsSection(List<Deal> deals) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hot Deals Near You',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DealsPage()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All >',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: deals.length,
              itemBuilder: (context, index) {
                final deal = deals[index];
                return DealCard(
                  deal: deal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
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

  Widget _buildBusinessesSection(List<Business> businesses) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Businesses',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DirectoryPage()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: businesses.length,
              itemBuilder: (context, index) {
                final b = businesses[index];
                return BusinessCard(
                  business: b,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
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

  Widget _buildJobsSection(List<Job> jobs) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            child: const Text(
              'Latest Jobs',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return JobCard(
                  job: job,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobDetailPage(jobId: job.id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "We haven't found any Habesha businesses or events here yet. The community is growing, but this spot is still untouched.",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loadHomeData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadHomeData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }


  Future<void> _navigateToLocationSelection() async {
    final result = await Navigator.push<LocationEntity>(
      context,
      MaterialPageRoute(builder: (_) => const LocationSelectionPage()),
    );
    if (result != null) {
      if (widget.useSessionDeviceLocation) {
        context.read<SessionDeviceLocationCubit>().setSessionLocation(result);
      } else {
        setState(() {
          _currentLocation = result;
        });
      }
      _loadHomeData();
    }
  }
}

class _RecommendationChip extends StatelessWidget {
  const _RecommendationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandPrimary : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.brandPrimary : AppColors.backgroundGrey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RecommendationBusinessCard extends StatelessWidget {
  const _RecommendationBusinessCard({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessDetailPage(businessId: business.id),
          ),
        );
      },
      child: Container(
        width: 200,
        height:150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                business.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: AppColors.backgroundGrey,
                  child: const Icon(Icons.store, size: 40, color: AppColors.textSecondary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        business.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
