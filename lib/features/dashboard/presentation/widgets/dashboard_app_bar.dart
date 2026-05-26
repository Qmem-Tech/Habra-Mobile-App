import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notification_icon_with_badge.dart';
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
    this.onRefresh,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final String userId;
  final BusinessPresence? selectedPresence;
  final VoidCallback onBusinessTap;
  final Future<void> Function() onNotificationsTap;
  final VoidCallback? onRefresh;

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront, size: 18, color: AppColors.textOnPrimary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textOnPrimary),
            ],
          ),
        ),
      ),
      actions: [
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: onRefresh,
            tooltip: 'Refresh',
          ),
        NotificationIconWithBadge(
          userId: userId,
          onOpenNotifications: onNotificationsTap,
        ),
      ],
    );
  }
}
