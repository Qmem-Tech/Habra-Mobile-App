import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/location/profile_home_city_sync.dart';
import '../../../../core/location/session_device_location_cubit.dart';
import '../../../../core/navigation/main_nav_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notification_icon_with_badge.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../home/domain/entities/location_entity.dart';
import '../../../home/presentation/pages/location_selection_page.dart';
import '../../../home/presentation/pages/notification_page.dart';
import '../bloc/jobs_cubit.dart';
import '../bloc/jobs_state.dart';
import '../widgets/featured_job_card.dart';
import '../widgets/recent_job_card.dart';
import '../widgets/job_category_chip.dart';
import '../../domain/entities/job_filters.dart';
import '../../domain/entities/job_listing.dart';
import '../../domain/job_quick_filter_options.dart';
import 'job_detail_page.dart';
import 'job_filters_bottom_sheet.dart';
import 'jobs_section_list_page.dart';
import 'no_jobs_found_page.dart';

class JobsPage extends StatefulWidget {
  final String? initialLocation;

  const JobsPage({super.key, this.initialLocation});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _currentLocation;
  String _selectedJobTypeChip = kJobsQuickFilterAll;
  JobFilters? _activeFilters;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation ?? 'Washington, D.C.';
  }

  String _resolvedLocationLabel(BuildContext context) {
    return SessionDeviceLocationCubit.tryLabel(context) ??
        _currentLocation ??
        'Washington, D.C.';
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LocationEntity>(
      context,
      MaterialPageRoute(builder: (_) => const LocationSelectionPage()),
    );
    if (!mounted || result == null) return;
    SessionDeviceLocationCubit.maybeOf(context)?.setSessionLocation(result);
    setState(() => _currentLocation = result.fullDisplayName);
    await persistProfileHomeCityIfSignedIn(context, result);
    if (!mounted) return;
    _loadJobs(context, null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadJobs(BuildContext? context, JobsCubit? cubit) {
    final ctx = context ?? this.context;
    final jobsCubit = cubit ?? ctx.read<JobsCubit>();
    final loc = SessionDeviceLocationCubit.tryLabel(ctx) ??
        _currentLocation ??
        'Washington, D.C.';
    jobsCubit.loadJobs(
      location: loc,
      filters: _activeFilters,
      searchQuery: _searchController.text.isEmpty
          ? null
          : _searchController.text,
    );
  }

  void _showFilters() async {
    final ctx = context;
    final filters = await showModalBottomSheet<JobFilters>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JobFiltersBottomSheet(
        initialFilters: _activeFilters,
      ),
    );

    if (!ctx.mounted) return;
    if (filters != null) {
      setState(() {
        _activeFilters = filters;
        _syncJobTypeChipFromFilters();
      });
    }
    if (!ctx.mounted) return;
    if (filters != null) {
      _loadJobs(ctx, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionCubit = SessionDeviceLocationCubit.maybeOf(context);
    final scaffold = Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildJobTypeQuickFilters(),
            Expanded(
              child: BlocBuilder<JobsCubit, JobsState>(
                builder: (context, state) {
                  if (state is JobsLoading) {
                    return const HabraCircularLoader(fullScreen: true);
                  }

                  if (state is JobsError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    );
                  }

                  if (state is JobsLoaded) {
                    if (state.jobs.isEmpty) {
                      return NoJobsFoundPage(
                        location: _resolvedLocationLabel(context),
                        onLocationChange: () {
                          _openLocationPicker();
                        },
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        _loadJobs(context, null);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFeaturedJobs(state.featuredJobs),
                            const SizedBox(height: 24),
                            _buildRecentJobs(state.recentJobs),
                          ],
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );

    final synced = sessionCubit == null
        ? scaffold
        : BlocListener<SessionDeviceLocationCubit, SessionDeviceLocationState>(
            listenWhen: (prev, curr) => curr is SessionDeviceLocationReady,
            listener: (context, state) {
              if (state is SessionDeviceLocationReady) {
                setState(
                  () => _currentLocation = state.location.fullDisplayName,
                );
                _loadJobs(context, null);
              }
            },
            child: scaffold,
          );

    return BlocProvider(
      create: (context) {
        final cubit = di.sl<JobsCubit>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final loc = SessionDeviceLocationCubit.tryLabel(context) ??
              _currentLocation ??
              'Washington, D.C.';
          cubit.loadJobs(
            location: loc,
            filters: _activeFilters,
            searchQuery: _searchController.text.isEmpty
                ? null
                : _searchController.text,
          );
        });
        return cubit;
      },
      child: synced,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              MainNavScope.maybeOf(context)?.scaffoldKey.currentState?.openDrawer();
            },
            icon: const Icon(Icons.menu, color: AppColors.textPrimary, size: 26),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _openLocationPicker,
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
                          _resolvedLocationLabel(context),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.customerHomePrimary,
                          ),
                          maxLines: 1,
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
            ),
          ),
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search jobs',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) {
                _loadJobs(context, null);
              },
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              onPressed: _showFilters,
              icon: const Icon(Icons.tune_rounded),
              color: AppColors.textPrimary,
              tooltip: 'Filters',
            ),
          ),
        ],
      ),
    );
  }

  /// Keeps the highlighted chip in sync when filters come from the sheet
  /// (e.g. one job type selected) or when multiple types are chosen.
  void _syncJobTypeChipFromFilters() {
    final types = _activeFilters?.jobTypes ?? [];
    if (types.length == 1 && kJobsQuickFilterJobTypes.contains(types.first)) {
      _selectedJobTypeChip = types.first;
    } else {
      _selectedJobTypeChip = kJobsQuickFilterAll;
    }
  }

  Widget _buildJobTypeQuickFilters() {
    final chips = jobsQuickFilterChipLabels();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = chips[index];
          final isSelected = _selectedJobTypeChip == label;
          return JobCategoryChip(
            label: label,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedJobTypeChip = label;
                if (label == kJobsQuickFilterAll) {
                  _activeFilters = _activeFilters?.copyWith(jobTypes: []) ??
                      const JobFilters();
                } else {
                  _activeFilters = (_activeFilters ?? const JobFilters())
                      .copyWith(jobTypes: [label]);
                }
              });
              final cubit = context.read<JobsCubit>();
              final loc = _resolvedLocationLabel(context);
              cubit.loadJobs(
                location: loc,
                filters: _activeFilters,
                searchQuery: _searchController.text.isEmpty
                    ? null
                    : _searchController.text,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFeaturedJobs(List<JobListing> featuredJobs) {
    if (featuredJobs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Jobs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.customerHomePrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                final cubit = context.read<JobsCubit>();
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: JobsSectionListPage(
                        title: 'Featured jobs',
                        jobs: featuredJobs,
                      ),
                    ),
                  ),
                );
              },
              child: const Text(
                'View All >',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.customerHomePrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 268,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featuredJobs.length,
            itemBuilder: (context, index) {
              final job = featuredJobs[index];
              return FeaturedJobCard(
                job: job,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobDetailPage(jobId: job.id),
                    ),
                  );
                },
                onApply: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobDetailPage(jobId: job.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentJobs(List<JobListing> recentJobs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Jobs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.customerHomePrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                final cubit = context.read<JobsCubit>();
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: JobsSectionListPage(
                        title: 'Recent jobs',
                        jobs: recentJobs,
                      ),
                    ),
                  ),
                );
              },
              child: const Text(
                'View All >',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.customerHomePrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentJobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final job = recentJobs[index];
            return RecentJobCard(
              job: job,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobDetailPage(jobId: job.id),
                  ),
                );
              },
              onBookmark: () {
                context.read<JobsCubit>().toggleBookmark(
                      job.id,
                      !job.isBookmarked,
                    );
              },
            );
          },
        ),
      ],
    );
  }
}
