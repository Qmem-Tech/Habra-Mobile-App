import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/domain/entities/business_presence.dart';

/// Reusable app bar for dashboard: menu, business selector, notifications.
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({
    super.key,
    required this.scaffoldKey,
    required this.userId,
    this.selectedPresence,
    required this.onBusinessTap,
    required this.onNotificationsTap,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final String userId;
  final BusinessPresence? selectedPresence;
  final VoidCallback onBusinessTap;
  final VoidCallback onNotificationsTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final label = selectedPresence != null
        ? '${selectedPresence!.shortDisplayName} - ${selectedPresence!.locationName ?? selectedPresence!.state ?? ""}'
        : 'Select business';
    return AppBar(
      backgroundColor: AppColors.backgroundWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
        onPressed: () => scaffoldKey.currentState?.openDrawer(),
      ),
      title: GestureDetector(
        onTap: onBusinessTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront, size: 18, color: AppColors.brandPrimary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.brandPrimary),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: onNotificationsTap,
        ),
      ],
    );
  }
}
