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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    di.sl<PushNotificationService>().registerTokenForUser(widget.user.id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void navigateToTab(int index, {int? dashboardTab}) {
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
