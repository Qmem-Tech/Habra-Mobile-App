import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../../../home/presentation/pages/business_owner_notification_page.dart';
import '../../../home/presentation/pages/business_locations_page.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';
import '../../../home/presentation/widgets/business_owner_drawer.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_tab_bar.dart';
import 'dashboard_analytics_tab.dart';
import 'dashboard_deals_tab.dart';
import 'dashboard_jobs_tab.dart';
import 'dashboard_reviews_tab.dart';
import 'create_deal_page.dart';
import 'create_job_post_page.dart';
import 'job_applicants_page.dart';
import 'reply_to_review_page.dart';
import '../../domain/entities/dashboard_job.dart';
import '../../domain/entities/business_review.dart';

/// Main dashboard page: Analytics, Deals, Jobs, Reviews tabs.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.user});

  final User user;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    if (homeState is BusinessOwnerHomeLoaded && homeState.selectedPresence != null) {
      final id = homeState.selectedPresence!.id;
      if (id != 'all') {
        context.read<DashboardCubit>().loadDashboard(id);
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
              );
            },
          ),
        ),
        body: Column(
          children: [
            DashboardTabBar(
              currentIndex: _tabIndex,
              onTap: (index) {
                setState(() => _tabIndex = index);
              },
            ),
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

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessOwnerNotificationPage(userId: widget.user.id),
      ),
    );
  }

  void _navigateToCreateDeal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateDealPage(),
      ),
    );
  }

  void _navigateToCreateJob() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateJobPostPage(),
      ),
    );
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReplyToReviewPage(review: review),
      ),
    );
  }
}
