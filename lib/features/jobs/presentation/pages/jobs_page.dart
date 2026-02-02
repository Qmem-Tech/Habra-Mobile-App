import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../bloc/jobs_cubit.dart';
import '../bloc/jobs_state.dart';
import '../widgets/featured_job_card.dart';
import '../widgets/recent_job_card.dart';
import '../widgets/job_category_chip.dart';
import '../../domain/entities/job_filters.dart';
import 'job_detail_page.dart';
import 'job_filters_bottom_sheet.dart';
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
  String _selectedCategory = 'All Jobs';
  List<String> _categories = ['All Jobs'];
  JobFilters? _activeFilters;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation ?? 'Washington, D.C.';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadJobs(BuildContext? context, JobsCubit? cubit) {
    final jobsCubit = cubit ?? (context ?? this.context).read<JobsCubit>();
    jobsCubit.loadJobs(
      location: _currentLocation,
      filters: _activeFilters,
      searchQuery: _searchController.text.isEmpty
          ? null
          : _searchController.text,
    );
  }

  void _showFilters() async {
    final filters = await showModalBottomSheet<JobFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JobFiltersBottomSheet(
        initialFilters: _activeFilters,
      ),
    );

    if (!context.mounted) return;
    if (filters != null) {
      setState(() {
        _activeFilters = filters;
      });
    }
    if (!context.mounted) return;
    if (filters != null) {
      _loadJobs(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = di.sl<JobsCubit>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cubit.loadJobCategories();
          cubit.loadJobs(
            location: _currentLocation,
            filters: _activeFilters,
            searchQuery: _searchController.text.isEmpty
                ? null
                : _searchController.text,
          );
        });
        return cubit;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildCategoryFilters(),
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
                          location: _currentLocation,
                          onLocationChange: () {
                            // TODO: Implement location change
                          },
                        );
                      }

                      return RefreshIndicator(
                      onRefresh: () async {
                        _loadJobs(context, null);
                      },
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(Icons.menu),
            color: AppColors.textPrimary,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: Show location picker
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimaryLight.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.brandPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _currentLocation ?? 'Select Location',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: AppColors.brandPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Navigate to notifications
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
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
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search jobs',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilters,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          _loadJobs(context, null);
        },
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return BlocBuilder<JobsCubit, JobsState>(
      builder: (context, state) {
        if (state is JobCategoriesLoaded) {
          _categories = state.categories;
        }

        return SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              return JobCategoryChip(
                label: category,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    if (category == 'All Jobs') {
                      _activeFilters = _activeFilters?.copyWith(
                        categories: [],
                      );
                    } else {
                      _activeFilters = (_activeFilters ?? const JobFilters())
                          .copyWith(categories: [category]);
                    }
                  });
                  // Use the context from BlocBuilder
                  final cubit = context.read<JobsCubit>();
                  cubit.loadJobs(
                    location: _currentLocation,
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
      },
    );
  }

  Widget _buildFeaturedJobs(List featuredJobs) {
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all featured jobs
              },
              child: const Text(
                'View All >',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
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

  Widget _buildRecentJobs(List recentJobs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Jobs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all recent jobs
              },
              child: const Text(
                'View All >',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentJobs.length,
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
