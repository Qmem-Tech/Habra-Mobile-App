import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/main_navigation_wrapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/pages/sign_in_page.dart';
import '../../../../injection/injection_container.dart' as di;
import 'profile_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../saved_items/presentation/bloc/saved_items_cubit.dart';
import '../../../saved_items/presentation/pages/saved_items_page.dart';
import '../../../explore/presentation/pages/my_reviews_page.dart';
import '../../../jobs/presentation/pages/my_applications_page.dart';
import '../../../jobs/presentation/bloc/job_applications_cubit.dart';
import '../../../events/presentation/pages/my_tickets_page.dart';

class NavigationDrawer extends StatelessWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final String? avatarUrl;

  const NavigationDrawer({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
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
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.backgroundGrey.withValues(alpha:0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with online indicator
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPrimary.withValues(alpha:0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl!,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
              ),
              // Online indicator
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // User name
          Text(
            userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          // User email
          Text(
            userEmail.isNotEmpty ? userEmail : 'user@example.com',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha:0.8),
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // View Profile link
          InkWell(
            onTap: () {
              Navigator.pop(context);
              final user = User(
                id: userId,
                email: userEmail.isNotEmpty ? userEmail : 'user@example.com',
                name: userName,
                role: UserRole.customer,
                avatarUrl: avatarUrl,
              );
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(user: user),
                ),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'View Profile',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.brandSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
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
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        title: 'Home',
        isActive: true,
        onTap: () {
          Navigator.pop(context);
        },
      ),
      _MenuItemData(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        title: 'Events',
        onTap: () {
          Navigator.pop(context);
          MainNavigationWrapper.navigateToTab(context, 1);
        },
      ),
      _MenuItemData(
        icon: Icons.confirmation_number_outlined,
        activeIcon: Icons.confirmation_number,
        title: 'My Tickets',
        onTap: () {
          Navigator.pop(context);
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MyTicketsPage(initialUpcoming: true),
            ),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.bookmark_outline,
        activeIcon: Icons.bookmark,
        title: 'Saved Items',
        onTap: () {
          Navigator.pop(context);
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => di.sl<SavedItemsCubit>()..loadSavedItems(),
                child: const SavedItemsPage(),
              ),
            ),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.rate_review_outlined,
        activeIcon: Icons.rate_review,
        title: 'My Review',
        onTap: () {
          Navigator.pop(context);
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyReviewsPage()),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.apps_outlined,
        activeIcon: Icons.apps,
        title: 'My Applications',
        onTap: () {
          Navigator.pop(context);
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => di.sl<JobApplicationsCubit>(),
                child: const MyApplicationsPage(),
              ),
            ),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        title: 'Settings',
        onTap: () {
          Navigator.pop(context);
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
        },
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: menuItems.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: AppColors.backgroundGrey.withValues(alpha:0.3),
        indent: 72,
      ),
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _buildMenuItem(context, item);
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItemData item) {
    final isActive = item.isActive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 24,
                  color: isActive ? AppColors.brandPrimary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 20),
              // Title
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? AppColors.brandPrimary : AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOut(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.backgroundGrey.withValues(alpha:0.3),
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            context.read<AuthCubit>().logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SignInPage()),
              (route) => false,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 24,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 20),
                const Text(
                  'Sign out',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  _MenuItemData({
    required this.icon,
    required this.activeIcon,
    required this.title,
    this.isActive = false,
    required this.onTap,
  });
}
