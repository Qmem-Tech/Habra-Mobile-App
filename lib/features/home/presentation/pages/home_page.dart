import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../../../../core/navigation/main_nav_scope.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final String userName;
  final LocationEntity? currentLocation;

  const HomePage({
    super.key,
    required this.userId,
    required this.userName,
    this.currentLocation,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LocationEntity? _currentLocation;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.currentLocation ?? const LocationEntity(
      id: 'default',
      city: 'Washington',
      state: 'D.C.',
      country: 'USA',
    );
    _loadHomeData();
  }

  void _loadHomeData() {
    final location = _currentLocation?.fullDisplayName ?? 'Washington, D.C.';
    context.read<HomeCubit>().loadHomeData(location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
  }

  Widget _buildContent(HomeState state) {
    final events = state is HomeLoaded ? state.events : <Event>[];
    final deals = state is HomeLoaded ? state.deals : <Deal>[];
    final businesses = state is HomeLoaded ? state.businesses : <Business>[];
    final jobs = state is HomeLoaded ? state.jobs : <Job>[];

    return CustomScrollView(
      slivers: [
        _buildHeader(),
        _buildGreetingSection(),
        _buildSearchSection(),
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
        onTap: () => _navigateToLocationSelection(),
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
                  _currentLocation?.fullDisplayName ?? 'Washington, D.C.',
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
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {
            final scope = MainNavScope.maybeOf(context);
            Navigator.push(
              context,
              MaterialPageRoute(
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

  Widget _buildEventsSection(List<dynamic> events) {
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
                return EventCard(event: events[index]);
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
                  onPressed: () {}, // TODO: Navigate to all deals
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
                return DealCard(deal: deals[index]);
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
                  onPressed: () {}, // TODO: Navigate to all businesses
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
                return BusinessCard(business: businesses[index]);
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
            "It's quiet in ${_currentLocation?.city ?? 'your location'}",
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
            onPressed: () => _navigateToLocationSelection(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Change Location'),
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
      setState(() {
        _currentLocation = result;
      });
      _loadHomeData();
    }
  }
}
