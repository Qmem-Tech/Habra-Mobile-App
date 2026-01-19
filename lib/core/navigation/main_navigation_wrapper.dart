import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/events/presentation/pages/events_page.dart';
import '../../features/explore/presentation/pages/explore_page.dart';

// Global key to access navigation from anywhere
final GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();

class MainNavigationWrapper extends StatefulWidget {
  final Widget homePage;
  final int initialIndex;
  final String? eventsLocation;

  const MainNavigationWrapper({
    super.key,
    required this.homePage,
    this.initialIndex = 0,
    this.eventsLocation,
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
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
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          widget.homePage,
          EventsPage(location: widget.eventsLocation ?? 'Washington, D.C.'),
          const ExplorePage(),
          _buildPlaceholderPage('Messages'),
          _buildPlaceholderPage('Jobs'),
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
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Jobs',
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPage(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title Page\nComing Soon',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
