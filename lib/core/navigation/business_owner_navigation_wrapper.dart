import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_colors.dart';
import '../config/business_subscription_config.dart';
import '../../core/services/push_notification_service.dart';
import '../../injection/injection_container.dart' as di;
import '../../features/home/presentation/pages/business_owner_home_page.dart';
import '../../features/home/presentation/bloc/business_owner_subscription_cubit.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/pages/business_legal_documents_detail_page.dart';
import '../../features/boosts/presentation/bloc/boosts_cubit.dart';
import '../../features/boosts/presentation/pages/boosts_page.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/home/presentation/pages/profile_page.dart';
import '../../features/home/presentation/pages/business_owner_subscription_page.dart';

/// Bottom nav for business owner: Home, Dash, Boosts, Profile.
class BusinessOwnerNavigationWrapper extends StatefulWidget {
  final User user;
  final int initialIndex;

  const BusinessOwnerNavigationWrapper({
    super.key,
    required this.user,
    this.initialIndex = 0,
  });

  /// Navigate to tab. [dashboardTab] when [index] is 1: 0=Analytics, 1=Deals, 2=Jobs, 3=Reviews.
  static void navigateToTab(BuildContext context, int index, {int? dashboardTab}) {
    final state =
        context.findAncestorStateOfType<_BusinessOwnerNavigationWrapperState>();
    state?.navigateToTab(index, dashboardTab: dashboardTab);
  }

  /// Call after legal docs (or similar) change so Dashboard access is re-checked on next open.
  static void invalidateBusinessToolsAccessCache(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_BusinessOwnerNavigationWrapperState>();
    state?._resetBusinessToolsAccessCache();
  }

  /// Opens business-owner subscription / paywall (requires [BusinessOwnerSubscriptionCubit] above context).
  static Future<void> openBusinessOwnerSubscription(
    BuildContext context,
    User user,
  ) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (ctx) => BlocProvider.value(
          value: context.read<BusinessOwnerSubscriptionCubit>(),
          child: BusinessOwnerSubscriptionPage(user: user),
        ),
      ),
    );
  }

  @override
  State<BusinessOwnerNavigationWrapper> createState() =>
      _BusinessOwnerNavigationWrapperState();
}

class _BusinessOwnerNavigationWrapperState
    extends State<BusinessOwnerNavigationWrapper> {
  late int _currentIndex;
  late PageController _pageController;
  int? _pendingDashboardTab;
  bool? _hasBusinessToolsAccess;
  bool _isCheckingBusinessToolsAccess = false;
  String? _blockedBusinessId;
  String? _blockedBusinessName;
  String? _lockReason;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    di.sl<PushNotificationService>().registerTokenForUser(widget.user.id);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasAccess = await _ensureBusinessToolsAccess(forceRefresh: true);
      if (!mounted) return;
      if (!hasAccess && _currentIndex != 0) {
        setState(() => _currentIndex = 0);
        _pageController.jumpToPage(0);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _resetBusinessToolsAccessCache() {
    if (!mounted) return;
    setState(() => _hasBusinessToolsAccess = null);
  }

  Future<bool> _ensureSubscriptionAccess() async {
    if (!BusinessSubscriptionConfig.gatesPaidBusinessTabs) {
      return true;
    }
    final cubit = context.read<BusinessOwnerSubscriptionCubit>();
    await cubit.refresh(widget.user.id);
    if (!mounted) return false;
    if (cubit.state.hasActiveSubscription) {
      return true;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'An active business subscription is required for the Dashboard.',
        ),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Subscribe',
          onPressed: () {
            BusinessOwnerNavigationWrapper.openBusinessOwnerSubscription(
              context,
              widget.user,
            );
          },
        ),
      ),
    );
    return false;
  }

  Future<bool> _ensureBusinessToolsAccess({bool forceRefresh = false}) async {
    if (!forceRefresh && _hasBusinessToolsAccess != null) {
      return _hasBusinessToolsAccess!;
    }
    if (_isCheckingBusinessToolsAccess) {
      return _hasBusinessToolsAccess ?? false;
    }
    _isCheckingBusinessToolsAccess = true;
    try {
      final dashboardCubit = context.read<DashboardCubit>();
      final businesses = await dashboardCubit.getOwnerBusinesses(widget.user.id);
      if (businesses.isEmpty) {
        _hasBusinessToolsAccess = false;
        _lockReason = 'No businesses found.';
        return false;
      }
      for (final business in businesses) {
        final approvalStatus = (business.statusText ?? '').toLowerCase();
        final isApproved = approvalStatus == 'approved';
        if (!isApproved) {
          _hasBusinessToolsAccess = false;
          _blockedBusinessId = business.id;
          _blockedBusinessName = business.name;
          _lockReason = 'Your business listing is pending approval.';
          return false;
        }
        // Super Admin approval is the source of truth for opening Dashboard/Boosts.
        // We only hard-block here when we can read legal rows and at least one is rejected.
        LegalDocumentsStatus legalStatus;
        try {
          legalStatus = await dashboardCubit.getLegalDocumentsStatus(business.id);
        } catch (_) {
          // RLS/network/parse issues: do not lock out an approved listing.
          continue;
        }
        if (legalStatus.hasRejected) {
          _hasBusinessToolsAccess = false;
          _blockedBusinessId = business.id;
          _blockedBusinessName = business.name;
          _lockReason = 'A legal document was rejected. Please re-upload a corrected file.';
          return false;
        }
      }
      _hasBusinessToolsAccess = true;
      _blockedBusinessId = null;
      _blockedBusinessName = null;
      _lockReason = null;
      return true;
    } catch (_) {
      _hasBusinessToolsAccess = false;
      return false;
    } finally {
      _isCheckingBusinessToolsAccess = false;
    }
  }

  Future<void> navigateToTab(int index, {int? dashboardTab}) async {
    if (index == 1 || index == 2) {
      final canAccessBusinessTools = await _ensureBusinessToolsAccess();
      if (!mounted) return;
      if (!canAccessBusinessTools) {
        final reason = _lockReason ??
            'Business dashboard is locked until your listing is approved and legal documents are submitted.';
        final bizId = _blockedBusinessId;
        final bizName = _blockedBusinessName;
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(reason),
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            action: bizId != null
                ? SnackBarAction(
                    label: 'View Documents',
                    textColor: AppColors.brandSecondaryLight,
                    onPressed: () {
                      messenger.hideCurrentSnackBar();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BusinessLegalDocumentsDetailPage(
                            businessId: bizId,
                            businessName: bizName ?? 'Business',
                          ),
                        ),
                      );
                    },
                  )
                : SnackBarAction(
                    label: 'OK',
                    textColor: AppColors.brandSecondaryLight,
                    onPressed: () => messenger.hideCurrentSnackBar(),
                  ),
          ),
        );
        return;
      }
      // Boosts (2) stays reachable so owners can purchase; Dashboard (1) is gated.
      if (index == 1) {
        final canAccessSubscription = await _ensureSubscriptionAccess();
        if (!mounted || !canAccessSubscription) return;
      }
    }

    final shouldAnimate = _currentIndex != index;
    setState(() {
      if (dashboardTab != null && index == 1) {
        _pendingDashboardTab = dashboardTab;
      }
      if (shouldAnimate) {
        _currentIndex = index;
      }
    });
    if (shouldAnimate) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    if (dashboardTab != null && index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pendingDashboardTab = null);
      });
    }
  }

  void _onTabTapped(int index) {
    navigateToTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          BusinessOwnerHomePage(user: widget.user),
          DashboardPage(user: widget.user, initialTabIndex: _pendingDashboardTab),
          BlocProvider(
            create: (_) => di.sl<BoostsCubit>(),
            child: BoostsPage(user: widget.user),
          ),
          ProfilePage(user: widget.user),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.brandPrimary,
        unselectedItemColor: AppColors.textSecondary,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dash',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rocket_launch_outlined),
            activeIcon: Icon(Icons.rocket_launch),
            label: 'Boosts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

}
