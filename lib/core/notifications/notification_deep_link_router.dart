import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/events/presentation/pages/event_detail_page.dart';
import '../../features/explore/presentation/pages/business_detail_page.dart';
import '../../features/explore/presentation/pages/deal_detail_page.dart';
import '../../features/home/domain/entities/notification_entity.dart';
import '../../features/home/presentation/pages/notification_page.dart';
import '../../features/jobs/presentation/pages/job_detail_page.dart';
import '../navigation/main_navigation_wrapper.dart';
import 'notification_route_payload.dart';

/// Opens a screen from FCM / local notification data, using [mainNavigatorKey].
class NotificationDeepLinkRouter {
  NotificationDeepLinkRouter._();

  /// Same routing contract as FCM `data`, for in-app notification rows / buttons.
  static void openFromNotificationEntity(NotificationEntity n) {
    final t = _typeStringFromEnum(n.type);
    openFromPayload(
      NotificationRoutePayload(
        type: t,
        actionId: n.actionId,
        notificationId: n.id,
      ),
    );
  }

  static String _typeStringFromEnum(NotificationType t) {
    switch (t) {
      case NotificationType.message:
        return 'message';
      case NotificationType.deal:
        return 'deal';
      case NotificationType.event:
        return 'event';
      case NotificationType.job:
        return 'job';
      case NotificationType.review:
        return 'review';
      case NotificationType.general:
        return 'general';
    }
  }

  static void openFromPayload(NotificationRoutePayload? payload) {
    final nav = mainNavigatorKey.currentState;
    if (nav == null || payload == null) return;

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    if (!payload.hasDeepLinkTarget) {
      _openNotificationList(nav, uid);
      return;
    }

    final type = payload.type!;
    final id = payload.actionId!;

    switch (_kindFromType(type)) {
      case _DeepLinkKind.job:
        nav.push<void>(
          MaterialPageRoute<void>(builder: (_) => JobDetailPage(jobId: id)),
        );
      case _DeepLinkKind.event:
        nav.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => EventDetailPage(eventId: id),
          ),
        );
      case _DeepLinkKind.deal:
        nav.push<void>(
          MaterialPageRoute<void>(builder: (_) => DealDetailPage(dealId: id)),
        );
      case _DeepLinkKind.review:
      case _DeepLinkKind.business:
        nav.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => BusinessDetailPage(businessId: id),
          ),
        );
      case _DeepLinkKind.message:
      case _DeepLinkKind.general:
        _openNotificationList(nav, uid);
    }
  }

  static void _openNotificationList(NavigatorState nav, String uid) {
    nav.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NotificationPage(userId: uid),
      ),
    );
  }
}

enum _DeepLinkKind {
  job,
  event,
  deal,
  review,
  business,
  message,
  general,
}

_DeepLinkKind _kindFromType(String type) {
  switch (type) {
    case 'job':
      return _DeepLinkKind.job;
    case 'event':
      return _DeepLinkKind.event;
    case 'deal':
      return _DeepLinkKind.deal;
    case 'review':
      return _DeepLinkKind.review;
    case 'business':
    case 'listing':
      return _DeepLinkKind.business;
    case 'message':
      return _DeepLinkKind.message;
    case 'general':
      return _DeepLinkKind.general;
    default:
      return _DeepLinkKind.general;
  }
}
