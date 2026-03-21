import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/business_owner_navigation_wrapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../home/domain/entities/business_presence.dart';
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../../../home/presentation/pages/business_owner_notification_page.dart';
import '../../../home/presentation/pages/business_locations_page.dart';
import '../../../home/presentation/widgets/business_owner_drawer.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_tab_bar.dart';
import '../widgets/dashboard_summary_header.dart';
import 'dashboard_analytics_tab.dart';
import 'dashboard_deals_tab.dart';
import 'dashboard_jobs_tab.dart';
import 'dashboard_reviews_tab.dart';
import 'create_deal_page.dart';
import 'create_job_post_page.dart';
import 'edit_business_page.dart';
import 'update_hours_page.dart';
import 'job_applicants_page.dart';
import 'reply_to_review_page.dart';
import '../../domain/entities/dashboard_job.dart';
import '../../domain/entities/business_review.dart';

/// Main dashboard page: Analytics, Deals, Jobs, Reviews tabs.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.user, this.initialTabIndex});

  final User user;
  /// When set, dashboard opens on this tab (0=Analytics, 1=Deals, 2=Jobs, 3=Reviews).
  final int? initialTabIndex;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex ?? 0;
    _loadDashboard();
  }

  @override
  void didUpdateWidget(DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newTab = widget.initialTabIndex;
    if (newTab != null && newTab != oldWidget.initialTabIndex) {
      setState(() => _tabIndex = newTab);
    }
  }

  Future<void> _loadDashboard() async {
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    if (homeState is BusinessOwnerHomeLoaded && homeState.selectedPresence != null) {
      final id = homeState.selectedPresence!.id;
      if (id != 'all') {
        await context.read<DashboardCubit>().loadDashboard(id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
      listener: (context, state) {
        if (state is BusinessOwnerHomeLoaded &&
            state.selectedPresence != null &&
            state.selectedPresence!.id != 'all') {
          context.read<DashboardCubit>().loadDashboard(state.selectedPresence!.id);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: BlocBuilder<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
          builder: (context, state) {
            final selectedPresence =
                state is BusinessOwnerHomeLoaded ? state.selectedPresence : null;
            return BusinessOwnerDrawer(
              userId: widget.user.id,
              userName: widget.user.name,
              userEmail: widget.user.email,
              selectedBusiness: selectedPresence,
              onHomeTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 0),
              onDashboardTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 1),
              onBoostListingTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 2),
              onEditBusinessTap: () {
                if (selectedPresence != null && selectedPresence.id != 'all') {
                  final dashboardCubit = context.read<DashboardCubit>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider<DashboardCubit>.value(
                        value: dashboardCubit,
                        child: EditBusinessPage(business: selectedPresence),
                      ),
                    ),
                  );
                }
              },
              onUpdateHoursTap: () {
                if (selectedPresence != null && selectedPresence.id != 'all') {
                  final dashboardCubit = context.read<DashboardCubit>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider<DashboardCubit>.value(
                        value: dashboardCubit,
                        child: UpdateHoursPage(businessId: selectedPresence.id),
                      ),
                    ),
                  );
                }
              },
              onSettingsTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            );
          },
        ),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: BlocBuilder<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
            builder: (context, state) {
              final presence = state is BusinessOwnerHomeLoaded ? state.selectedPresence : null;
              return DashboardAppBar(
                scaffoldKey: _scaffoldKey,
                userId: widget.user.id,
                selectedPresence: presence,
                onBusinessTap: _openBusinessLocations,
                onNotificationsTap: _openNotifications,
                onRefresh: _loadDashboard,
              );
            },
          ),
        ),
        body: Column(
          children: [
            BlocBuilder<DashboardCubit, DashboardState>(
              buildWhen: (_, current) => current is DashboardTabState,
              builder: (context, state) {
                if (state is DashboardTabState) {
                  return DashboardSummaryHeader(
                    activeDealsCount: state.activeDealsCount,
                    activeJobsCount: state.activeJobsCount,
                    rating: state.analytics?.rating,
                    reviewCount: state.analytics?.reviewCount,
                    onDealsTap: () => setState(() => _tabIndex = 1),
                    onJobsTap: () => setState(() => _tabIndex = 2),
                    onReviewsTap: () => setState(() => _tabIndex = 3),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            DashboardTabBar(
              currentIndex: _tabIndex,
              onTap: (index) {
                setState(() => _tabIndex = index);
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<DashboardCubit, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardLoading || state is DashboardInitial) {
                    if (state is DashboardInitial) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final homeState = context.read<BusinessOwnerHomeCubit>().state;
                        if (homeState is BusinessOwnerHomeLoaded &&
                            homeState.selectedPresence != null &&
                            homeState.selectedPresence!.id != 'all') {
                          context.read<DashboardCubit>().loadDashboard(homeState.selectedPresence!.id);
                        }
                      });
                    }
                    return const HabraCircularLoader(fullScreen: true);
                  }
                  if (state is DashboardError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _loadDashboard,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state is! DashboardTabState) {
                    return const SizedBox.shrink();
                  }
                  switch (_tabIndex) {
                    case 0:
                      return DashboardAnalyticsTab(
                        analytics: state.analytics,
                        onQuickStatTap: (_) {},
                        onRefresh: _loadDashboard,
                      );
                    case 1:
                      return DashboardDealsTab(
                        deals: state.deals,
                        filter: state.dealsFilter,
                        onFilterChanged: (f) {
                          final homeState = context.read<BusinessOwnerHomeCubit>().state;
                          if (homeState is BusinessOwnerHomeLoaded &&
                              homeState.selectedPresence != null &&
                              homeState.selectedPresence!.id != 'all') {
                            context.read<DashboardCubit>().setDealsFilter(
                                  homeState.selectedPresence!.id,
                                  f,
                                );
                          }
                        },
                        onCreateDeal: () => _navigateToCreateDeal(),
                        onEdit: (_) {},
                        onPause: (_) {},
                        onStats: (_) {},
                      );
                    case 2:
                      return DashboardJobsTab(
                        jobs: state.jobs,
                        filter: state.jobsFilter,
                        onFilterChanged: (f) =>
                            context.read<DashboardCubit>().setJobsFilter(f),
                        onCreateJob: () => _navigateToCreateJob(),
                        onViewApplicants: (job) => _navigateToApplicants(job),
                      );
                    case 3:
                      return DashboardReviewsTab(
                        overview: state.reviewsOverview,
                        reviews: state.reviews,
                        onRespond: (r) => _navigateToReplyToReview(r),
                        onEditResponse: (r) => _navigateToReplyToReview(r),
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
        floatingActionButton: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is! DashboardTabState) return const SizedBox.shrink();
            if (_tabIndex == 1) {
              return FloatingActionButton(
                onPressed: _navigateToCreateDeal,
                backgroundColor: AppColors.brandSecondary,
                child: const Icon(Icons.add, color: AppColors.textOnPrimary),
              );
            }
            if (_tabIndex == 2) {
              return FloatingActionButton(
                onPressed: _navigateToCreateJob,
                backgroundColor: AppColors.brandSecondary,
                child: const Icon(Icons.add, color: AppColors.textOnPrimary),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Future<void> _openBusinessLocations() async {
    final cubit = context.read<BusinessOwnerHomeCubit>();
    final state = cubit.state;
    final loaded = state is BusinessOwnerHomeLoaded ? state : null;
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessLocationsPage(
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

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessOwnerNotificationPage(userId: widget.user.id),
      ),
    );
  }

  void _navigateToCreateDeal() async {
    final dashboardCubit = context.read<DashboardCubit>();
    final homeCubit = context.read<BusinessOwnerHomeCubit>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<DashboardCubit>.value(value: dashboardCubit),
            BlocProvider<BusinessOwnerHomeCubit>.value(value: homeCubit),
          ],
          child: const CreateDealPage(),
        ),
      ),
    );
    if (result == true && mounted) {
      _loadDashboard();
    }
  }

  void _navigateToCreateJob() async {
    final dashboardCubit = context.read<DashboardCubit>();
    final homeCubit = context.read<BusinessOwnerHomeCubit>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<DashboardCubit>.value(value: dashboardCubit),
            BlocProvider<BusinessOwnerHomeCubit>.value(value: homeCubit),
          ],
          child: const CreateJobPostPage(),
        ),
      ),
    );
    if (result == true && mounted) {
      _loadDashboard();
    }
  }

  void _navigateToApplicants(DashboardJob job) {
    final dashboardCubit = context.read<DashboardCubit>();
    final homeCubit = context.read<BusinessOwnerHomeCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<DashboardCubit>.value(value: dashboardCubit),
            BlocProvider<BusinessOwnerHomeCubit>.value(value: homeCubit),
          ],
          child: JobApplicantsPage(
            jobId: job.id,
            jobTitle: job.title,
            jobSubtitle: '${job.location} • ${job.postedTimeAgo}',
          ),
        ),
      ),
    );
  }

  void _navigateToReplyToReview(BusinessReview review) {
    final dashboardCubit = context.read<DashboardCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider<DashboardCubit>.value(
          value: dashboardCubit,
          child: ReplyToReviewPage(review: review),
        ),
      ),
    );
  }
}
