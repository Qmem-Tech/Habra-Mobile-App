import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/pages/sign_in_page.dart';
import '../../domain/entities/business_presence.dart';

/// Drawer for business owner: business profile header + menu (Home, Dashboard, Messages, etc.).
class BusinessOwnerDrawer extends StatelessWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final BusinessPresence? selectedBusiness;
  final VoidCallback? onHomeTap;
  final VoidCallback? onDashboardTap;
  final VoidCallback? onMessagesTap;
  final VoidCallback? onEditBusinessTap;
  /// Opens the public business detail screen (Explore listing) for the selection.
  final VoidCallback? onViewPublicListingTap;
  final VoidCallback? onBusinessPhotosTap;
  final VoidCallback? onUpdateHoursTap;
  final VoidCallback? onBoostListingTap;
  final VoidCallback? onSettingsTap;
  /// When false (no businesses yet), hides Dashboard, edit, hours, and Boosts.
  final bool showBusinessToolsMenu;
  /// When false, hides Dashboard (e.g. listing not yet approved).
  final bool showDashboardMenuItem;
  /// When false, hides Boosts (e.g. legal docs rejected).
  final bool showBoostsMenuItem;

  const BusinessOwnerDrawer({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.selectedBusiness,
    this.onHomeTap,
    this.onDashboardTap,
    this.onMessagesTap,
    this.onEditBusinessTap,
    this.onViewPublicListingTap,
    this.onBusinessPhotosTap,
    this.onUpdateHoursTap,
    this.onBoostListingTap,
    this.onSettingsTap,
    this.showBusinessToolsMenu = true,
    this.showDashboardMenuItem = true,
    this.showBoostsMenuItem = true,
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
    final business = selectedBusiness;
    final businessName = business?.name ?? 'My Business';
    final location = business?.locationDisplay ?? 'Business Account';
    final imageUrl = business?.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.backgroundGrey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _drawerBusinessIconAvatar(),
                      ),
                    )
                  : _drawerBusinessIconAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            businessName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (business?.isVerified == true) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.verified,
                            size: 20,
                            color: AppColors.brandSecondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Business Account • $location',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          business?.isPendingApproval == true
                              ? Icons.schedule
                              : Icons.check_circle,
                          size: 18,
                          color: business?.isPendingApproval == true
                              ? AppColors.brandPrimary
                              : AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          business?.isPendingApproval == true
                              ? 'Pending for approval'
                              : 'Listing Active',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: business?.isPendingApproval == true
                                ? AppColors.brandPrimary
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Shown when there is no listing image or the network image fails to load.
  Widget _drawerBusinessIconAvatar() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.storefront_outlined,
        size: 36,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final menuItems = <_DrawerMenuItemData>[
      _DrawerMenuItemData(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        title: 'Home',
        isActive: true,
        onTap: () {
          Navigator.pop(context);
          onHomeTap?.call();
        },
      ),
      if (showBusinessToolsMenu) ...[
        if (showDashboardMenuItem)
          _DrawerMenuItemData(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
              onDashboardTap?.call();
            },
          ),
        _DrawerMenuItemData(
          icon: Icons.edit_outlined,
          activeIcon: Icons.edit,
          title: 'Edit Business Info',
          onTap: () {
            Navigator.pop(context);
            onEditBusinessTap?.call();
          },
        ),
        if (selectedBusiness != null && onViewPublicListingTap != null)
          _DrawerMenuItemData(
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront,
            title: 'View public listing',
            onTap: () {
              Navigator.pop(context);
              onViewPublicListingTap?.call();
            },
          ),
        _DrawerMenuItemData(
          icon: Icons.photo_library_outlined,
          activeIcon: Icons.photo_library,
          title: 'Business photos',
          onTap: () {
            Navigator.pop(context);
            onBusinessPhotosTap?.call();
          },
        ),
        _DrawerMenuItemData(
          icon: Icons.schedule_outlined,
          activeIcon: Icons.schedule,
          title: 'Update Hours',
          onTap: () {
            Navigator.pop(context);
            onUpdateHoursTap?.call();
          },
        ),
        if (showBoostsMenuItem)
          _DrawerMenuItemData(
            icon: Icons.rocket_launch_outlined,
            activeIcon: Icons.rocket_launch,
            title: 'Boost Listing',
            iconColor: AppColors.brandPrimary,
            onTap: () {
              Navigator.pop(context);
              onBoostListingTap?.call();
            },
          ),
      ],
      _DrawerMenuItemData(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        title: 'Settings',
        onTap: () {
          Navigator.pop(context);
          onSettingsTap?.call();
        },
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: menuItems.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: AppColors.backgroundGrey.withValues(alpha: 0.3),
        indent: 72,
      ),
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _buildMenuItem(context, item);
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, _DrawerMenuItemData item) {
    final isActive = item.isActive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 24,
                  color: item.iconColor ??
                      (isActive ? AppColors.brandPrimary : AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 20),
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
        color: AppColors.backgroundWhite,
        border: Border(
          top: BorderSide(
            color: AppColors.backgroundGrey.withValues(alpha: 0.3),
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
            child: const Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Icon(
                    Icons.logout_rounded,
                    size: 24,
                    color: AppColors.error,
                  ),
                ),
                SizedBox(width: 20),
                Text(
                  'Sign out',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.error,
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

class _DrawerMenuItemData {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final bool isActive;
  final Color? iconColor;
  final VoidCallback onTap;

  _DrawerMenuItemData({
    required this.icon,
    required this.activeIcon,
    required this.title,
    this.isActive = false,
    this.iconColor,
    required this.onTap,
  });
}
