import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../bloc/notification_cubit.dart';
import '../bloc/notification_state.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationPage extends StatelessWidget {
  final String? userId;

  const NotificationPage({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final userId = this.userId ?? 'current_user'; // TODO: Get from auth

    return BlocProvider(
      create: (context) => di.sl<NotificationCubit>()..loadNotifications(userId),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppAssets.appLogo,
                height: 28,
                width: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.notifications, color: AppColors.brandPrimary),
              ),
              const SizedBox(width: 10),
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          centerTitle: true,
        ),
        body: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return HabraCircularLoader(fullScreen: true);
            }

            if (state is NotificationEmpty) {
              return _buildEmptyState();
            }

            if (state is NotificationError) {
              return _buildErrorState(state.message);
            }

            if (state is NotificationLoaded) {
              return _buildNotificationsList(state.notifications);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationEntity> notifications) {
    final grouped = _groupNotifications(notifications);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final group = grouped[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 12, top: index > 0 ? 24 : 0),
              child: Text(
                group['title'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: group['title'] == 'Today'
                      ? AppColors.brandPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            ...(group['notifications'] as List<NotificationEntity>).map((notification) {
              return _buildNotificationItem(notification);
            }),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _groupNotifications(List<NotificationEntity> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final todayList = <NotificationEntity>[];
    final yesterdayList = <NotificationEntity>[];
    final thisWeekList = <NotificationEntity>[];

    for (var notification in notifications) {
      final createdAt = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      if (createdAt == today) {
        todayList.add(notification);
      } else if (createdAt == yesterday) {
        yesterdayList.add(notification);
      } else if (createdAt.isAfter(weekAgo)) {
        thisWeekList.add(notification);
      }
    }

    final groups = <Map<String, dynamic>>[];
    if (todayList.isNotEmpty) {
      groups.add({'title': 'Today', 'notifications': todayList});
    }
    if (yesterdayList.isNotEmpty) {
      groups.add({'title': 'Yesterday', 'notifications': yesterdayList});
    }
    if (thisWeekList.isNotEmpty) {
      groups.add({'title': 'This Week', 'notifications': thisWeekList});
    }

    return groups;
  }

  Widget _buildNotificationItem(NotificationEntity notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationIcon(notification),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  notification.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _formatTime(notification.createdAt),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationEntity notification) {
    if (notification.imageUrl != null && notification.type != NotificationType.message) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          notification.imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultIcon(notification);
          },
        ),
      );
    }

    return _buildDefaultIcon(notification);
  }

  Widget _buildDefaultIcon(NotificationEntity notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.message:
        iconData = Icons.person;
        iconColor = AppColors.brandPrimary;
        break;
      case NotificationType.deal:
        iconData = Icons.local_offer;
        iconColor = AppColors.brandPrimary;
        break;
      case NotificationType.event:
        iconData = Icons.calendar_today;
        iconColor = AppColors.brandPrimary;
        break;
      case NotificationType.job:
        iconData = Icons.work;
        iconColor = AppColors.brandPrimary;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppColors.brandPrimary;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                AppAssets.appLogo,
                height: 64,
                width: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.notifications_off_rounded,
                  size: 64,
                  color: AppColors.brandPrimary.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'You have no new notifications right now. Check back later for updates from local businesses and the community.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading notifications',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
