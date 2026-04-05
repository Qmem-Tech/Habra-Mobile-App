import 'package:flutter/material.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../injection/injection_container.dart' as di;
import '../../core/navigation/main_nav_scope.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/events/presentation/pages/events_page.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/home/presentation/pages/navigation_drawer.dart' as app_drawer;
import '../../features/jobs/presentation/pages/jobs_page.dart';
import '../../features/home/presentation/pages/profile_tab_page.dart';

// Global key to access navigation from anywhere
final GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();

class MainNavigationWrapper extends StatefulWidget {
  final Widget homePage;
  final int initialIndex;
  final String? eventsLocation;
  /// User info for drawer and notifications. If null, no drawer is shown.
  final String? userId;
  final String? userName;
  final String? userEmail;
  /// Full user for Profile tab. When null, Profile tab still shown but may show placeholder.
  final User? user;
  /// Profile photo for drawer header (same source as [User.avatarUrl] when available).
  final String? userAvatarUrl;

  const MainNavigationWrapper({
    super.key,
    required this.homePage,
    this.initialIndex = 0,
    this.eventsLocation,
    this.userId,
    this.userName,
    this.userEmail,
    this.user,
    this.userAvatarUrl,
  });

  static void navigateToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainNavigationWrapperState>();
    state?.navigateToTab(index);
  }

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _currentIndex;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    if (widget.userId != null) {
      di.sl<PushNotificationService>().registerTokenForUser(widget.userId!);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void navigateToTab(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onTabTapped(int index) {
    navigateToTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final hasUser = widget.userId != null && widget.userName != null;
    return Scaffold(
      key: _scaffoldKey,
      drawer: hasUser
          ? app_drawer.NavigationDrawer(
              userId: widget.userId!,
              userName: widget.userName!,
              userEmail: widget.userEmail ?? '',
              avatarUrl: widget.userAvatarUrl ?? widget.user?.avatarUrl,
            )
          : null,
      body: MainNavScope(
        scaffoldKey: _scaffoldKey,
        userId: widget.userId,
        userName: widget.userName,
        userEmail: widget.userEmail,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            widget.homePage,
            EventsPage(location: widget.eventsLocation),
            ExplorePage(location: widget.eventsLocation),
            JobsPage(initialLocation: widget.eventsLocation),
            ProfileTabPage(user: widget.user),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.customerHomePrimary,
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
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Events',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.work_outline),
                activeIcon: Icon(Icons.work),
                label: 'Jobs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

}
