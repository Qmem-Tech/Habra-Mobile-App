import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../features/home/presentation/pages/business_owner_home_page.dart';
import '../../features/auth/domain/entities/user.dart';

/// Bottom nav for business owner: Home, Dash, Boosts, Messages, Profile.
class BusinessOwnerNavigationWrapper extends StatefulWidget {
  final User user;
  final int initialIndex;

  const BusinessOwnerNavigationWrapper({
    super.key,
    required this.user,
    this.initialIndex = 0,
  });

  static void navigateToTab(BuildContext context, int index) {
    final state =
        context.findAncestorStateOfType<_BusinessOwnerNavigationWrapperState>();
    state?.navigateToTab(index);
  }

  @override
  State<BusinessOwnerNavigationWrapper> createState() =>
      _BusinessOwnerNavigationWrapperState();
}

class _BusinessOwnerNavigationWrapperState
    extends State<BusinessOwnerNavigationWrapper> {
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
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          BusinessOwnerHomePage(user: widget.user),
          _buildPlaceholderPage('Dash'),
          _buildPlaceholderPage('Boosts'),
          _buildPlaceholderPage('Messages'),
          _buildPlaceholderPage('Profile'),
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
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message),
            label: 'Messages',
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

  Widget _buildPlaceholderPage(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Center(
        child: Text(
          '$title\nComing Soon',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
