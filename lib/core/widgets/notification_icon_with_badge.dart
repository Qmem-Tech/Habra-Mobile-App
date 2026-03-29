import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/notification_user_id.dart';
import '../../features/home/domain/repositories/notification_repository.dart';
import '../../injection/injection_container.dart' as di;

/// Notification bell with a red dot only when [NotificationRepository] reports unread items.
class NotificationIconWithBadge extends StatefulWidget {
  const NotificationIconWithBadge({
    super.key,
    this.userId,
    required this.onOpenNotifications,
    this.iconColor = AppColors.textPrimary,
    this.badgeColor = AppColors.error,
  });

  final String? userId;
  /// Open the notifications screen; awaited so unread count refreshes when the user returns.
  final Future<void> Function() onOpenNotifications;
  final Color iconColor;
  final Color badgeColor;

  @override
  State<NotificationIconWithBadge> createState() =>
      _NotificationIconWithBadgeState();
}

class _NotificationIconWithBadgeState extends State<NotificationIconWithBadge> {
  int _unreadCount = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    final resolved = resolveNotificationUserId(widget.userId);
    if (resolved == null) {
      if (mounted) {
        setState(() {
          _unreadCount = 0;
          _loaded = true;
        });
      }
      return;
    }
    final result = await di.sl<NotificationRepository>().getUnreadCount(resolved);
    final count = result.fold((_) => 0, (n) => n);
    if (mounted) {
      setState(() {
        _unreadCount = count;
        _loaded = true;
      });
    }
  }

  Future<void> _onPressed() async {
    await widget.onOpenNotifications();
    if (mounted) await _refreshCount();
  }

  @override
  Widget build(BuildContext context) {
    final showDot = _loaded && _unreadCount > 0;
    return IconButton(
      onPressed: _onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: widget.iconColor),
          if (showDot)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
