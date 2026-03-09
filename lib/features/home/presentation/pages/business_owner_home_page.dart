import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/business_owner_navigation_wrapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/business_presence.dart';
import '../../domain/entities/owner_snapshot_metrics.dart';
import '../../domain/entities/owner_activity_item.dart';
import '../../domain/entities/setup_task.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/job.dart';
import '../bloc/business_owner_home_cubit.dart';
import '../bloc/business_owner_home_state.dart';
import '../widgets/business_owner_drawer.dart';
import '../../../dashboard/presentation/pages/edit_business_page.dart';
import '../../../dashboard/presentation/pages/update_hours_page.dart';
import '../../../dashboard/presentation/pages/create_deal_page.dart';
import '../../../dashboard/presentation/pages/create_job_post_page.dart';
import '../../../dashboard/presentation/pages/job_applicants_page.dart';
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import 'business_owner_notification_page.dart';
import 'business_locations_page.dart';
import 'add_new_presence_page.dart';

class BusinessOwnerHomePage extends StatefulWidget {
  final User user;

  const BusinessOwnerHomePage({super.key, required this.user});

  @override
  State<BusinessOwnerHomePage> createState() => _BusinessOwnerHomePageState();
}

class _BusinessOwnerHomePageState extends State<BusinessOwnerHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    context.read<BusinessOwnerHomeCubit>().loadOwnerHome(
          ownerId: widget.user.id,
          showSetupIncomplete: false,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditBusinessPage(business: selectedPresence),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select a business first')),
                );
              }
            },
            onUpdateHoursTap: () {
              if (selectedPresence != null && selectedPresence.id != 'all') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UpdateHoursPage(businessId: selectedPresence.id),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select a business first')),
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
      body: SafeArea(
        child: BlocBuilder<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
          builder: (context, state) {
            if (state is BusinessOwnerHomeLoading) {
              return const HabraCircularLoader(fullScreen: true);
            }
            if (state is BusinessOwnerHomeError) {
              return _buildErrorView(state.message);
            }
            if (state is BusinessOwnerHomeLoaded) {
              if (state.isSetupIncomplete) {
                return _buildSetupIncompleteView(state);
              }
              if (state.isAllBusinessesView) {
                return _buildAllBusinessesView(state);
              }
              return _buildSingleBusinessView(state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BusinessOwnerHomeLoaded state, {
    required VoidCallback onBusinessSelectorTap,
  }) {
    final selected = state.selectedPresence;
    final label = selected != null
        ? '${selected.shortDisplayName}${selected.locationName != null ? " - ${selected.locationName}" : ""}'
        : 'All Businesses';

    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: AppColors.backgroundWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      centerTitle: false,
      title: GestureDetector(
        onTap: onBusinessSelectorTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront, size: 18, color: AppColors.brandPrimary),
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
              const Icon(Icons.arrow_drop_down,
                  size: 20, color: AppColors.brandPrimary),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined,
                  color: AppColors.textPrimary),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
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
  }

  Widget _buildSingleBusinessView(BusinessOwnerHomeLoaded state) {
    final presence = state.selectedPresence;

    return CustomScrollView(
      slivers: [
        _buildAppBar(state, onBusinessSelectorTap: _openBusinessLocations),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBusinessBanner(presence),
              _buildBannerTitleRow(presence),
              if (presence != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                  child: Row(
                    children: [
                      Text(
                        presence.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (presence.rating != null) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Icon(Icons.star, size: 16, color: AppColors.brandSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${presence.rating}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 20, AppResources.spacingM, 12),
                child: _buildSectionHeader(
                  'Today\'s Snapshot',
                  actionLabel: 'View Reports',
                  onActionTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 1, dashboardTab: 0),
                ),
              ),
              _buildSnapshotCards(state.snapshot),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 24, AppResources.spacingM, 12),
                child: _buildSectionHeader('Quick Actions'),
              ),
              _buildQuickActions(),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 24, AppResources.spacingM, 12),
                child: _buildSectionHeader(
                  'Recent Activity',
                  actionLabel: 'View All >',
                  onActionTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 1, dashboardTab: 3),
                ),
              ),
              _buildRecentActivityList(
                state.recentActivity,
                onReplyToReview: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 1, dashboardTab: 3),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 24, AppResources.spacingM, 12),
                child: _buildSectionHeader(
                  'Your Active Deals',
                  actionLabel: 'Manage',
                  onActionTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 1, dashboardTab: 1),
                ),
              ),
              _buildActiveDealsList(state.activeDeals),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 24, AppResources.spacingM, 12),
                child: _buildSectionHeader(
                  'Your Job Posts',
                  actionLabel: 'Manage',
                  onActionTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 1, dashboardTab: 2),
                ),
              ),
              _buildJobPostsList(state.jobPosts),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllBusinessesView(BusinessOwnerHomeLoaded state) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(state, onBusinessSelectorTap: _openBusinessLocations),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 20, AppResources.spacingM, 12),
                child: _buildSectionHeader(
                  'This Month (All Businesses)',
                  actionLabel: 'View Reports',
                  onActionTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 1, dashboardTab: 0),
                ),
              ),
              _buildSnapshotCards(state.snapshot),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 24, AppResources.spacingM, 12),
                child: const Text(
                  'Your Businesses',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildYourBusinessesList(state.presences),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM, vertical: 16),
                child: AppButton(
                  text: 'Add New Presence',
                  onPressed: () => _openAddNewPresence(context),
                  icon: Icons.add,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 8, AppResources.spacingM, 12),
                child: _buildSectionHeader('Quick Actions'),
              ),
              _buildQuickActions(),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 24, AppResources.spacingM, 12),
                child: _buildSectionHeader(
                  'Recent Activity',
                  actionLabel: 'View All >',
                  onActionTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 1, dashboardTab: 3),
                ),
              ),
              _buildRecentActivityList(
                state.recentActivity,
                onReplyToReview: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 1, dashboardTab: 3),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSetupIncompleteView(BusinessOwnerHomeLoaded state) {
    final completed = state.setupCompletedCount;
    final total = state.setupTasks.length;
    final progress = total > 0 ? completed / total : 0.0;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: GestureDetector(
            onTap: _openBusinessLocations,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront, size: 18, color: AppColors.brandPrimary),
                  const SizedBox(width: 6),
                  Text(
                    state.selectedPresence?.shortDisplayName ?? 'My Business',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.brandPrimary),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BusinessOwnerNotificationPage(userId: widget.user.id)),
                );
              },
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppResources.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Habra!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ) ?? const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s get your business set up for success in the Habesha community.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Setup Progress',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.progressInactive,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.progressActive),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completed of $total steps completed',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'To-Do List',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...state.setupTasks.asMap().entries.map((entry) {
                  final task = entry.value;
                  return _buildSetupTaskCard(
                    context,
                    task,
                    state: state,
                    isFirst: entry.key == 0,
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupTaskCard(
    BuildContext context,
    SetupTask task, {
    required BusinessOwnerHomeLoaded state,
    bool isFirst = false,
  }) {
    VoidCallback? onTap;
    VoidCallback? onButtonPressed;
    if (!task.isLocked) {
      switch (task.id) {
        case SetupTaskId.completeProfile:
          final presence = state.selectedPresence;
          if (presence != null && presence.id != 'all') {
            onTap = () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditBusinessPage(business: presence),
              ),
            );
          }
          break;
        case SetupTaskId.postFirstDeal:
          final presence = state.selectedPresence;
          if (presence != null && presence.id != 'all') {
            onTap = () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateDealPage()),
            );
          }
          break;
        case SetupTaskId.shareListing:
          onTap = () => BusinessOwnerNavigationWrapper.navigateToTab(context, 2);
          break;
      }
      onButtonPressed = onTap;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(AppResources.spacingL),
        margin: EdgeInsets.zero,
        backgroundColor: isFirst
            ? AppColors.backgroundWhite
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        onTap: task.isLocked ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: task.isLocked
                        ? AppColors.backgroundGrey
                        : AppColors.brandPrimary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: task.isLocked
                        ? Icon(Icons.lock_outline, size: 20, color: AppColors.textSecondary)
                        : Text(
                            '${task.order}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandPrimary,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (isFirst && task.actionLabel != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            text: task.actionLabel!,
                            onPressed: onButtonPressed,
                            height: 44,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (task.isLocked)
                  const Icon(Icons.lock_outline, size: 20, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessBanner(BusinessPresence? presence) {
    if (presence == null) return const SizedBox.shrink();

    final coverUrl = presence.imageUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppResources.radiusL),
            child: AspectRatio(
              aspectRatio: 2.2,
              child: Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.backgroundGrey,
                  child: Image.asset(
                    AppAssets.businessOwnerCoverPlaceholder,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 48),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: -24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGrey,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        AppAssets.businessOwnerLogoPlaceholder,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: presence.isOpenNow ? AppColors.success : AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        presence.isOpenNow ? 'Open Now' : 'Closed',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerTitleRow(BusinessPresence? presence) {
    if (presence == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 36, AppResources.spacingM, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  presence.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (presence.isVerified)
                const Icon(Icons.verified, color: AppColors.brandSecondary, size: 24),
            ],
          ),
          if (presence.isPendingApproval) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 16, color: AppColors.brandPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'Pending for approval',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.brandPrimary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSnapshotCards(OwnerSnapshotMetrics snapshot) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              icon: Icons.visibility_outlined,
              value: snapshot.viewsFormatted,
              changePercent: snapshot.viewsChangePercent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              icon: Icons.touch_app_outlined,
              value: snapshot.clicksFormatted,
              changePercent: snapshot.clicksChangePercent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              icon: Icons.chat_bubble_outline,
              value: snapshot.messagesFormatted,
              changePercent: snapshot.messagesChangePercent,
              isNegative: snapshot.messagesChangePercent < 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required double changePercent,
    bool isNegative = false,
  }) {
    final color = isNegative ? AppColors.error : AppColors.success;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      margin: EdgeInsets.zero,
      backgroundColor: AppColors.backgroundLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isNegative ? Icons.trending_down : Icons.trending_up,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                '~${changePercent.abs().round()}%',
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final state = context.read<BusinessOwnerHomeCubit>().state;
    final selectedPresence = state is BusinessOwnerHomeLoaded ? state.selectedPresence : null;
    final hasSpecificBusiness = selectedPresence != null && selectedPresence.id != 'all';

    final actions = [
      (Icons.sell, 'Post Deal', AppColors.brandPrimary, () async {
        if (!hasSpecificBusiness) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select a business first')),
          );
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateDealPage()),
        );
        if (!context.mounted) return;
        context.read<BusinessOwnerHomeCubit>().loadOwnerHome(ownerId: widget.user.id);
      }),
      (Icons.work_outline, 'Post Job', AppColors.textPrimary, () async {
        if (!hasSpecificBusiness) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select a business first')),
          );
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateJobPostPage()),
        );
        if (!context.mounted) return;
        context.read<BusinessOwnerHomeCubit>().loadOwnerHome(ownerId: widget.user.id);
      }),
      (Icons.campaign_outlined, 'Promote', AppColors.textPrimary, () {
        BusinessOwnerNavigationWrapper.navigateToTab(context, 2);
      }),
      (Icons.schedule, 'Hours', AppColors.textPrimary, () {
        if (!hasSpecificBusiness) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select a business first')),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UpdateHoursPage(businessId: selectedPresence!.id),
          ),
        );
      }),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((a) {
          return GestureDetector(
            onTap: a.$4,
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: a.$3 == AppColors.brandPrimary
                        ? AppColors.brandPrimary
                        : AppColors.backgroundLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    a.$1,
                    color: a.$3 == AppColors.brandPrimary ? AppColors.textOnPrimary : AppColors.textPrimary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  a.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivityList(
    List<OwnerActivityItem> items, {
    VoidCallback? onReplyToReview,
  }) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildActivityCard(item, onReplyToReview: onReplyToReview);
      },
    );
  }

  Widget _buildActivityCard(OwnerActivityItem item, {VoidCallback? onReplyToReview}) {
    IconData iconData;
    Color iconBg;
    switch (item.type) {
      case OwnerActivityType.review:
        iconData = Icons.star;
        iconBg = AppColors.brandSecondary.withValues(alpha: 0.3);
        break;
      case OwnerActivityType.applicant:
        iconData = Icons.person_add;
        iconBg = AppColors.info.withValues(alpha: 0.2);
        break;
      default:
        iconData = Icons.notifications;
        iconBg = AppColors.backgroundGrey;
    }

    final timeAgo = _formatTimeAgo(item.createdAt);

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppResources.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: AppColors.brandPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.body != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.body!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                if (item.actionLabel != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: onReplyToReview,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandPrimary,
                        side: const BorderSide(color: AppColors.brandPrimary),
                      ),
                      child: Text(item.actionLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDealsList(List<Deal> deals) {
    if (deals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
        child: Text(
          'No active deals.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      itemCount: deals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final deal = deals[index];
        final expiry = deal.expiryDate != null
            ? 'Expires in ${deal.expiryDate!.difference(DateTime.now()).inDays} days'
            : '';
        return AppCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 1, dashboardTab: 1),
          child: Row(
            children: [
              Icon(Icons.sell, color: AppColors.brandPrimary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (expiry.isNotEmpty)
                      Text(
                        expiry,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobPostsList(List<Job> jobs) {
    if (jobs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
        child: Text(
          'No job posts.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final job = jobs[index];
        return AppCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => _openJobApplicants(context, job),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${job.postedDate != null ? "5" : "0"} Applicants waiting',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYourBusinessesList(List<BusinessPresence> presences) {
    final list = presences.where((p) => p.id != 'all').take(5).toList();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = list[index];
        final viewCount = (1200 + index * 400).toString();
        return AppCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppResources.spacingM),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  p.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: AppColors.backgroundGrey,
                    child: const Icon(Icons.store),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      p.isPendingApproval
                          ? 'Pending for approval • ${p.locationDisplay}'
                          : '${p.category} • ${p.locationDisplay}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    viewCount,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              AppButton(
                text: 'Manage',
                onPressed: () => _manageBusiness(p),
                width: 90,
                height: 36,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.month}/${dateTime.day}';
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Error loading data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Retry',
              onPressed: () {
                context.read<BusinessOwnerHomeCubit>().loadOwnerHome(ownerId: widget.user.id);
              },
            ),
          ],
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

  void _openAddNewPresence(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddNewPresencePage(),
      ),
    );
  }

  void _openJobApplicants(BuildContext context, Job job) {
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
            jobSubtitle: '${job.jobType} • ${job.location ?? job.companyName}',
          ),
        ),
      ),
    );
  }

  void _manageBusiness(BusinessPresence p) {
    context.read<BusinessOwnerHomeCubit>().setSelectedPresenceId(p.id);
    BusinessOwnerNavigationWrapper.navigateToTab(context, 1, dashboardTab: 0);
  }
}
