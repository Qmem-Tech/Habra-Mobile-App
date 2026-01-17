import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/pages/login_page.dart';

class NavigationDrawer extends StatelessWidget {
  final String userId;
  final String userName;
  final String userEmail;

  const NavigationDrawer({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildMenuItems(context),
            ),
            _buildSignOut(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.brandPrimary.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // TODO: Navigate to profile page
            },
            child: Text(
              'View Profile',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.brandSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final menuItems = [
      _MenuItemData(
        icon: Icons.home,
        title: 'Home',
        color: AppColors.brandPrimary,
        onTap: () {
          Navigator.pop(context);
          // Already on home page
        },
      ),
      _MenuItemData(
        icon: Icons.calendar_today,
        title: 'Events',
        color: AppColors.textSecondary,
        onTap: () {
          Navigator.pop(context);
          // TODO: Navigate to events page
        },
      ),
      _MenuItemData(
        icon: Icons.groups,
        title: 'Community Groups',
        color: AppColors.textSecondary,
        onTap: () {
          Navigator.pop(context);
          // TODO: Navigate to community groups
        },
      ),
      _MenuItemData(
        icon: Icons.message,
        title: 'Messages',
        color: AppColors.textSecondary,
        onTap: () {
          Navigator.pop(context);
          // TODO: Navigate to messages
        },
      ),
      _MenuItemData(
        icon: Icons.confirmation_number,
        title: 'My Tickets',
        color: AppColors.textSecondary,
        onTap: () {
          Navigator.pop(context);
          // TODO: Navigate to tickets
        },
      ),
      _MenuItemData(
        icon: Icons.bookmark,
        title: 'Saved Items',
        color: AppColors.textSecondary,
        onTap: () {
          Navigator.pop(context);
          // TODO: Navigate to saved items
        },
      ),
      _MenuItemData(
        icon: Icons.rate_review,
        title: 'My Review',
        color: AppColors.textSecondary,
        onTap: () {
          Navigator.pop(context);
          // TODO: Navigate to reviews
        },
      ),
      _MenuItemData(
        icon: Icons.apps,
        title: 'My Applications',
        color: AppColors.textSecondary,
        onTap: () {
          Navigator.pop(context);
          // TODO: Navigate to applications
        },
      ),
      _MenuItemData(
        icon: Icons.settings,
        title: 'Settings',
        color: AppColors.textSecondary,
        onTap: () {
          Navigator.pop(context);
          // TODO: Navigate to settings
        },
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return ListTile(
          leading: Icon(item.icon, color: item.color),
          title: Text(
            item.title,
            style: TextStyle(
              fontSize: 16,
              color: item.color,
              fontWeight: item.color == AppColors.brandPrimary ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onTap: item.onTap,
        );
      },
    );
  }

  Widget _buildSignOut(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.backgroundGrey)),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Sign out',
          style: TextStyle(
            fontSize: 16,
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          context.read<AuthCubit>().logout();
          // Navigate to login page after logout
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        },
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  _MenuItemData({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}
