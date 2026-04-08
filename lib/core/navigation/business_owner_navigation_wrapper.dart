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
import '../../features/home/domain/entities/business_presence.dart';
import '../../features/home/presentation/bloc/business_owner_home_cubit.dart';
import '../../features/home/presentation/bloc/business_owner_home_state.dart';
import '../../features/home/presentation/pages/profile_page.dart';
import '../../features/home/presentation/pages/business_owner_subscription_page.dart';

/// Result of evaluating listing approval + legal-doc rules for owner navigation.
///
/// **Product rules**
/// - **Home** and **Profile** are always reachable.
/// - **Dashboard** uses the same focus listing as the dashboard APIs ([BusinessOwnerHomeLoaded.focusBusinessIdForOwnerTools]): that location must be `approved` and have no rejected legal row. Other locations do not block Dash for the selected one.
/// - **Boosts** uses the same focus listing for legal checks; listing may be pending/rejected so owners can still open Boosts. Blocked when there are no listings or the focus location has a rejected legal doc.
class BusinessOwnerNavToolsSnapshot {
  const BusinessOwnerNavToolsSnapshot({
    required this.dashboardEnabled,
    required this.boostsEnabled,
    required this.gateEvaluated,
    this.userMessage,
    this.primaryBlockedBusinessId,
    this.primaryBlockedBusinessName,
    this.showLegalDocumentsSnackAction = false,
  });

  final bool dashboardEnabled;
  final bool boostsEnabled;
  /// False until the first gate computation finishes (UI may treat as “unknown”).
  final bool gateEvaluated;
  final String? userMessage;
  final String? primaryBlockedBusinessId;
  final String? primaryBlockedBusinessName;
  /// When true, blocked-flow snackbars may offer “View Documents”.
  final bool showLegalDocumentsSnackAction;
}

/// Bottom nav for business owner: Home, Dash, Boosts, Profile.
class BusinessOwnerNavigationWrapper extends StatefulWidget {
  final User user;
  final int initialIndex;

  const BusinessOwnerNavigationWrapper({
    super.key,
    required this.user,
    this.initialIndex = 0,
  });

  /// Navigate to tab. [dashboardTab] when [index] is 1: 0=Analytics, 1=Deals, 2=Jobs, 3=Events, 4=Reviews.
  static void navigateToTab(BuildContext context, int index, {int? dashboardTab}) {
    final state =
        context.findAncestorStateOfType<_BusinessOwnerNavigationWrapperState>();
    state?.navigateToTab(index, dashboardTab: dashboardTab);
  }

  /// Pops the current route (e.g. [ListingStatusPage]) then switches to the Home tab.
  /// No-op for the tab switch if this context is not under [BusinessOwnerNavigationWrapper].
  static void popCurrentRouteAndOpenHome(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_BusinessOwnerNavigationWrapperState>();
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state?.mounted ?? false) {
        state!.navigateToTab(0);
      }
    });
  }

  /// Call after legal docs (or similar) change so Dashboard access is re-checked on next open.
  static void invalidateBusinessToolsAccessCache(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_BusinessOwnerNavigationWrapperState>();
    state?._resetBusinessToolsAccessCache();
  }

  /// Latest gate snapshot for drawer / banners; null before first evaluation.
  static BusinessOwnerNavToolsSnapshot? toolsSnapshotOf(BuildContext context) {
    return context
        .findAncestorStateOfType<_BusinessOwnerNavigationWrapperState>()
        ?._toolsSnapshot;
  }

  static bool drawerShowDashboardMenu(BuildContext context) {
    final s = toolsSnapshotOf(context);
    if (s == null || !s.gateEvaluated) return true;
    return s.dashboardEnabled;
  }

  static bool drawerShowBoostsMenu(BuildContext context) {
    final s = toolsSnapshotOf(context);
    if (s == null || !s.gateEvaluated) return true;
    return s.boostsEnabled;
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
  static const double _disabledNavOpacity = 0.38;

  late int _currentIndex;
  late PageController _pageController;
  int? _pendingDashboardTab;
  BusinessOwnerNavToolsSnapshot? _toolsSnapshot;
  Future<BusinessOwnerNavToolsSnapshot>? _gateFuture;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    di.sl<PushNotificationService>().registerTokenForUser(widget.user.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      di.sl<PushNotificationService>().consumePendingDeepLink();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final snap = await _ensureToolsSnapshot(forceRefresh: true);
      if (!mounted) return;
      if (!snap.dashboardEnabled && _currentIndex == 1) {
        setState(() => _currentIndex = 0);
        _pageController.jumpToPage(0);
      }
      if (!snap.boostsEnabled && _currentIndex == 2) {
        setState(() => _currentIndex = 0);
        _pageController.jumpToPage(0);
      }
    });
  }

  @override
  void didUpdateWidget(BusinessOwnerNavigationWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user.id != oldWidget.user.id) {
      di.sl<PushNotificationService>().registerTokenForUser(widget.user.id);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _resetBusinessToolsAccessCache() {
    if (!mounted) return;
    setState(() {
      _toolsSnapshot = null;
      _gateFuture = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureToolsSnapshot(forceRefresh: true);
    });
  }

  void _refreshToolsGateDueToHomeChange() {
    if (!mounted) return;
    setState(() {
      _toolsSnapshot = null;
      _gateFuture = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final snap = await _ensureToolsSnapshot(forceRefresh: true);
      if (!mounted) return;
      if (!snap.dashboardEnabled && _currentIndex == 1) {
        setState(() => _currentIndex = 0);
        _pageController.jumpToPage(0);
      }
      if (!snap.boostsEnabled && _currentIndex == 2) {
        setState(() => _currentIndex = 0);
        _pageController.jumpToPage(0);
      }
    });
  }

  Future<BusinessOwnerNavToolsSnapshot> _ensureToolsSnapshot({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      _toolsSnapshot = null;
      _gateFuture = null;
    }
    if (_toolsSnapshot != null) {
      return _toolsSnapshot!;
    }
    if (_gateFuture != null) {
      return _gateFuture!;
    }
    _gateFuture = _computeToolsSnapshot().whenComplete(() {
      if (mounted) {
        setState(() => _gateFuture = null);
      } else {
        _gateFuture = null;
      }
    });
    return _gateFuture!;
  }

  Future<BusinessOwnerNavToolsSnapshot> _computeToolsSnapshot() async {
    try {
      final dashboardCubit = context.read<DashboardCubit>();
      final homeCubit = context.read<BusinessOwnerHomeCubit>();
      final homeState = homeCubit.state;

      final businesses = await dashboardCubit.getOwnerBusinesses(widget.user.id);
      final real = businesses.where((b) => b.id != 'all').toList();
      if (real.isEmpty) {
        const userMessage = 'No businesses found.';
        final snap = BusinessOwnerNavToolsSnapshot(
          dashboardEnabled: false,
          boostsEnabled: false,
          gateEvaluated: true,
          userMessage: userMessage,
          showLegalDocumentsSnackAction: false,
        );
        if (mounted) setState(() => _toolsSnapshot = snap);
        return snap;
      }

      String? focusId;
      if (homeState is BusinessOwnerHomeLoaded) {
        focusId = homeState.focusBusinessIdForOwnerTools;
      }
      focusId ??= real.first.id;

      final BusinessPresence focus = real.any((b) => b.id == focusId)
          ? real.firstWhere((b) => b.id == focusId)
          : real.first;
      focusId = focus.id;

      final raw = (focus.statusText ?? '').toLowerCase().trim();
      final listingApproved = raw == 'approved';

      String? listingMessage;
      if (!listingApproved) {
        if (raw == 'rejected') {
          listingMessage =
              '${focus.name}: listing was rejected. Update this location or contact support if you need help.';
        } else {
          listingMessage =
              '${focus.name}: listing is pending approval. Dashboard opens here once this location is approved.';
        }
      }

      var focusLegalRejected = false;
      try {
        focusLegalRejected = (await dashboardCubit.getLegalDocumentsStatus(focusId))
            .hasRejected;
      } catch (_) {
        focusLegalRejected = false;
      }

      if (focusLegalRejected) {
        final snap = BusinessOwnerNavToolsSnapshot(
          dashboardEnabled: false,
          boostsEnabled: false,
          gateEvaluated: true,
          userMessage:
              'A legal document was rejected for ${focus.name}. Re-upload a corrected file to continue.',
          primaryBlockedBusinessId: focusId,
          primaryBlockedBusinessName: focus.name,
          showLegalDocumentsSnackAction: true,
        );
        if (mounted) setState(() => _toolsSnapshot = snap);
        return snap;
      }

      if (!listingApproved) {
        final snap = BusinessOwnerNavToolsSnapshot(
          dashboardEnabled: false,
          boostsEnabled: true,
          gateEvaluated: true,
          userMessage: listingMessage,
          primaryBlockedBusinessId: focusId,
          primaryBlockedBusinessName: focus.name,
          showLegalDocumentsSnackAction: false,
        );
        if (mounted) setState(() => _toolsSnapshot = snap);
        return snap;
      }

      final snap = const BusinessOwnerNavToolsSnapshot(
        dashboardEnabled: true,
        boostsEnabled: true,
        gateEvaluated: true,
        userMessage: null,
        primaryBlockedBusinessId: null,
        primaryBlockedBusinessName: null,
        showLegalDocumentsSnackAction: false,
      );
      if (mounted) setState(() => _toolsSnapshot = snap);
      return snap;
    } catch (_) {
      const userMessage =
          'Could not verify your business status. Check your connection and try again.';
      final snap = BusinessOwnerNavToolsSnapshot(
        dashboardEnabled: false,
        boostsEnabled: false,
        gateEvaluated: true,
        userMessage: userMessage,
        showLegalDocumentsSnackAction: false,
      );
      if (mounted) setState(() => _toolsSnapshot = snap);
      return snap;
    }
  }

  void _showGateSnackBar(BusinessOwnerNavToolsSnapshot snap) {
    final reason = snap.userMessage ??
        'This section is not available yet. Finish listing approval and legal requirements from Home.';
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final bizId = snap.primaryBlockedBusinessId;
    final showDocs = snap.showLegalDocumentsSnackAction && bizId != null;
    messenger.showSnackBar(
      SnackBar(
        content: Text(reason),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: showDocs
            ? SnackBarAction(
                label: 'View Documents',
                textColor: AppColors.brandSecondaryLight,
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BusinessLegalDocumentsDetailPage(
                        businessId: bizId,
                        businessName:
                            snap.primaryBlockedBusinessName ?? 'Business',
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

  Future<void> navigateToTab(int index, {int? dashboardTab}) async {
    final snap = await _ensureToolsSnapshot();
    if (!mounted) return;

    if (index == 1 && !snap.dashboardEnabled) {
      _showGateSnackBar(snap);
      return;
    }
    if (index == 2 && !snap.boostsEnabled) {
      _showGateSnackBar(snap);
      return;
    }

    if (index == 1) {
      final canAccessSubscription = await _ensureSubscriptionAccess();
      if (!mounted || !canAccessSubscription) return;
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

  BottomNavigationBarItem _navBarItem({
    required IconData outlined,
    required IconData filled,
    required String label,
    required bool enabledWhenGated,
  }) {
    final snap = _toolsSnapshot;
    final gated = snap?.gateEvaluated ?? false;
    final enabled = !gated || enabledWhenGated;
    final opacity = enabled ? 1.0 : _disabledNavOpacity;
    return BottomNavigationBarItem(
      icon: Opacity(opacity: opacity, child: Icon(outlined)),
      activeIcon: Opacity(opacity: opacity, child: Icon(filled)),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final snap = _toolsSnapshot;
    final dashEnabled = snap == null || !snap.gateEvaluated || snap.dashboardEnabled;
    final boostEnabled = snap == null || !snap.gateEvaluated || snap.boostsEnabled;

    return BlocListener<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
      listenWhen: (prev, curr) {
        if (curr is! BusinessOwnerHomeLoaded) {
          return prev is BusinessOwnerHomeLoaded;
        }
        if (prev is! BusinessOwnerHomeLoaded) return true;
        return prev.selectedPresenceId != curr.selectedPresenceId ||
            prev.presences != curr.presences;
      },
      listener: (context, state) => _refreshToolsGateDueToHomeChange(),
      child: Scaffold(
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
            DashboardPage(
              user: widget.user,
              initialTabIndex: _pendingDashboardTab,
            ),
            BlocProvider(
              create: (_) => di.sl<BoostsCubit>(),
              child: BoostsPage(user: widget.user),
            ),
            ProfilePage(user: widget.user),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.backgroundWhite,
          elevation: 12,
          selectedItemColor: AppColors.ownerHomePrimary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            _navBarItem(
              outlined: Icons.home_outlined,
              filled: Icons.home,
              label: 'Home',
              enabledWhenGated: true,
            ),
            _navBarItem(
              outlined: Icons.dashboard_outlined,
              filled: Icons.dashboard,
              label: 'Dash',
              enabledWhenGated: dashEnabled,
            ),
            _navBarItem(
              outlined: Icons.rocket_launch_outlined,
              filled: Icons.rocket_launch,
              label: 'Boosts',
              enabledWhenGated: boostEnabled,
            ),
            _navBarItem(
              outlined: Icons.person_outline,
              filled: Icons.person,
              label: 'Profile',
              enabledWhenGated: true,
            ),
          ],
        ),
      ),
    );
  }

}
