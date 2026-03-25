import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_colors.dart';
import '../../core/services/push_notification_service.dart';
import '../../injection/injection_container.dart' as di;
import '../../features/home/presentation/pages/business_owner_home_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/boosts/presentation/bloc/boosts_cubit.dart';
import '../../features/boosts/presentation/pages/boosts_page.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../features/home/presentation/pages/profile_page.dart';

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
        return false;
      }
      for (final business in businesses) {
        final approvalStatus = (business.statusText ?? '').toLowerCase();
        final isApproved = approvalStatus == 'approved';
        if (!isApproved) {
          _hasBusinessToolsAccess = false;
          return false;
        }
        final legalStatus =
            await dashboardCubit.getLegalDocumentsStatus(business.id);
        if (!legalStatus.hasRequiredUploaded || !legalStatus.isFullyApproved) {
          _hasBusinessToolsAccess = false;
          return false;
        }
      }
      _hasBusinessToolsAccess = true;
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Business dashboard is locked until email is verified, legal documents are submitted, and admin approval is completed.',
            ),
          ),
        );
        return;
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
