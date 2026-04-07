import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../bloc/notification_cubit.dart';
import '../bloc/notification_state.dart';
import '../../domain/entities/notification_entity.dart';

enum NotificationFilter { all, reviews, messages, jobs }

/// Business owner notifications with filter tabs (All, Reviews, Messages, Jobs).
class BusinessOwnerNotificationPage extends StatefulWidget {
  final String? userId;

  const BusinessOwnerNotificationPage({super.key, this.userId});

  @override
  State<BusinessOwnerNotificationPage> createState() =>
      _BusinessOwnerNotificationPageState();
}

class _BusinessOwnerNotificationPageState
    extends State<BusinessOwnerNotificationPage> {
  NotificationFilter _filter = NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          di.sl<NotificationCubit>()..loadNotifications(widget.userId),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
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
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildFilterTabs(),
            Expanded(
              child: BlocBuilder<NotificationCubit, NotificationState>(
                builder: (context, state) {
                  if (state is NotificationLoading) {
                    return const HabraCircularLoader(fullScreen: true);
                  }
                  if (state is NotificationEmpty) {
                    return _buildEmptyState(hint: state.hint);
                  }
                  if (state is NotificationError) {
                    return _buildErrorState(state.message);
                  }
                  if (state is NotificationLoaded) {
                    final filtered = _filterNotifications(state.notifications);
                    return _buildNotificationList(filtered);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      (NotificationFilter.all, 'All'),
      (NotificationFilter.reviews, 'Reviews'),
      (NotificationFilter.messages, 'Messages'),
      (NotificationFilter.jobs, 'Jobs'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM, vertical: 12),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandPrimary : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<NotificationEntity> _filterNotifications(List<NotificationEntity> list) {
    switch (_filter) {
      case NotificationFilter.reviews:
        return list.where((n) => n.type == NotificationType.review).toList();
      case NotificationFilter.messages:
        return list.where((n) => n.type == NotificationType.message).toList();
      case NotificationFilter.jobs:
        return list.where((n) => n.type == NotificationType.job).toList();
      case NotificationFilter.all:
        return list;
    }
  }

  Widget _buildNotificationList(List<NotificationEntity> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final n = notifications[index];
        return _buildNotificationCard(n);
      },
    );
  }

  Widget _buildNotificationCard(NotificationEntity n) {
    final timeAgo = _formatTime(n.createdAt);
    IconData iconData;
    Color iconBg;

    switch (n.type) {
      case NotificationType.review:
        iconData = Icons.star;
        iconBg = AppColors.brandSecondary.withValues(alpha: 0.3);
        break;
      case NotificationType.job:
        iconData = Icons.work_outline;
        iconBg = AppColors.info.withValues(alpha: 0.2);
        break;
      case NotificationType.message:
        return _buildMessageItem(n, timeAgo);
      default:
        iconData = Icons.notifications;
        iconBg = AppColors.backgroundGrey;
    }

    String? actionLabel;
    if (n.type == NotificationType.review) actionLabel = 'View Review';
    if (n.type == NotificationType.job && n.description.contains('Applicant')) {
      actionLabel = 'Review Application';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppResources.spacingL),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppResources.radiusM),
                ),
                child: Icon(iconData, color: AppColors.brandPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    await _editNotification(n);
                    return;
                  }
                  if (value == 'delete') {
                    await _deleteNotification(n);
                  }
                },
                itemBuilder: (_) {
                  final editable = _isUserCreatedNotification(n);
                  return [
                    if (editable)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ];
                },
              ),
            ],
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: actionLabel,
                onPressed: () {},
                height: 44,
                backgroundColor: actionLabel == 'Review Application'
                    ? AppColors.brandPrimary
                    : AppColors.brandPrimary.withValues(alpha: 0.2),
                textColor: actionLabel == 'Review Application'
                    ? AppColors.textOnPrimary
                    : AppColors.brandPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageItem(NotificationEntity n, String timeAgo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: n.imageUrl != null ? NetworkImage(n.imageUrl!) : null,
            child: n.imageUrl == null
                ? const Icon(Icons.person, color: AppColors.textSecondary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  n.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                await _editNotification(n);
                return;
              }
              if (value == 'delete') {
                await _deleteNotification(n);
              }
            },
            itemBuilder: (_) {
              final editable = _isUserCreatedNotification(n);
              return [
                if (editable)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ];
            },
          ),
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  bool _isUserCreatedNotification(NotificationEntity n) {
    return !n.id.startsWith('platform_notif:');
  }

  Future<void> _deleteNotification(NotificationEntity n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('This notification will be removed from your list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await context.read<NotificationCubit>().deleteNotification(n.id);
    if (!mounted) return;
    if (ok) {
      await context.read<NotificationCubit>().loadNotifications(widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not delete notification')),
    );
  }

  Future<void> _editNotification(NotificationEntity n) async {
    final titleController = TextEditingController(text: n.title);
    final descriptionController = TextEditingController(text: n.description);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (confirmed != true) return;
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    if (title.isEmpty || description.isEmpty) return;
    final ok = await context.read<NotificationCubit>().updateNotification(
          n.id,
          title: title,
          description: description,
        );
    if (!mounted) return;
    if (ok) {
      await context.read<NotificationCubit>().loadNotifications(widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification updated')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not update notification')),
    );
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.month}/${dateTime.day}';
  }

  Widget _buildEmptyState({String? hint}) {
    final title = hint != null ? 'No notifications' : 'All caught up!';
    final subtitle = hint ??
        'You have no new notifications in this category. Check back later for updates.';

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
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Error loading notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'Try again',
              onPressed: () =>
                  context.read<NotificationCubit>().loadNotifications(widget.userId),
              width: 200,
            ),
          ],
        ),
      ),
    );
  }
}
