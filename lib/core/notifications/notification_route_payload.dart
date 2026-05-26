import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

/// Aligns with Supabase `notifications.type` and `data->>'action_id'`
/// (see [NotificationSupabaseDataSource._parseActionId]).
class NotificationRoutePayload {
  const NotificationRoutePayload({
    this.type,
    this.actionId,
    this.notificationId,
    this.rawData = const {},
  });

  final String? type;
  final String? actionId;
  final String? notificationId;
  final Map<String, dynamic> rawData;

  bool get hasDeepLinkTarget =>
      actionId != null &&
      actionId!.isNotEmpty &&
      type != null &&
      type!.isNotEmpty;

  static NotificationRoutePayload? fromRemoteMessage(RemoteMessage message) {
    return fromStringKeyedMap(Map<String, dynamic>.from(message.data));
  }

  /// FCM data payloads are string-keyed string values.
  static NotificationRoutePayload? fromStringKeyedMap(
    Map<String, dynamic> data,
  ) {
    if (data.isEmpty) return null;
    final type = _readString(data, const ['type', 'notification_type']);
    final actionId = _readString(data, const ['action_id', 'actionId']);
    final notificationId =
        _readString(data, const ['notification_id', 'notificationId']);
    return NotificationRoutePayload(
      type: type?.toLowerCase(),
      actionId: actionId,
      notificationId: notificationId,
      rawData: Map<String, dynamic>.from(data),
    );
  }

  static NotificationRoutePayload? fromLocalNotificationPayload(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return null;
      final m = Map<String, dynamic>.from(
        decoded.map((k, v) => MapEntry(k.toString(), v)),
      );
      return fromStringKeyedMap(m);
    } catch (_) {
      return null;
    }
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }
}
