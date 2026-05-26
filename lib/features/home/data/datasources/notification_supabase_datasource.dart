import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/notification_table_config.dart';
import '../../../../core/constants/supabase_tables.dart';
import 'notification_remote_datasource.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';

/// Supabase implementation of [NotificationRemoteDataSource].
/// Uses `public.notifications` plus optional `platform_notifications` (merged when readable).
class NotificationSupabaseDataSource implements NotificationRemoteDataSource {
  NotificationSupabaseDataSource();

  static const String _platformIdPrefix = 'platform_notif:';

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    final personal = await SupabaseFailureMapper.guard(() => _client
        .from(SupabaseTables.notifications)
        .select()
        .eq(kNotificationsRecipientColumn, userId)
        .order('created_at', ascending: false)
        .limit(100));

    final list = (personal as List<dynamic>)
        .map((e) => _rowToModel(Map<String, dynamic>.from(e as Map)))
        .toList();

    final platform = await _fetchPlatformNotificationsForUser(userId);
    final merged = [...list, ...platform];
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  Future<List<NotificationModel>> _fetchPlatformNotificationsForUser(String userId) async {
    try {
      final role = await _profileRoleRaw(userId);
      final res = await _client
          .from(SupabaseTables.platformNotifications)
          .select('id, title, body, audience, created_at')
          .order('created_at', ascending: false)
          .limit(50);
      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows
          .where((row) => _audienceMatches(parseString(row['audience']) ?? 'all', role))
          .map(_platformRowToModel)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> _profileRoleRaw(String userId) async {
    try {
      final res = await _client
          .from(SupabaseTables.profiles)
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      if (res is Map<String, dynamic>) {
        return parseString(res['role']);
      }
    } catch (_) {}
    return null;
  }

  static bool _audienceMatches(String audience, String? profileRole) {
    final a = audience.toLowerCase().trim();
    if (a.isEmpty || a == 'all') return true;
    final r = (profileRole ?? 'customer').toLowerCase().replaceAll(' ', '');
    if (a == 'business_owners' || a == 'business_owner') {
      return r == 'businessowner' || r == 'admin';
    }
    if (a == 'customers' || a == 'customer') {
      return r == 'customer' || r == 'guest';
    }
    return true;
  }

  NotificationModel _platformRowToModel(Map<String, dynamic> row) {
    final rawId = parseStringRequired(row['id']);
    final title = parseStringRequired(row['title'], 'Notice');
    final body = parseStringRequired(row['body'], '');
    final createdAt = parseTimestamp(row['created_at']) ?? DateTime.now();
    return NotificationModel(
      id: '$_platformIdPrefix$rawId',
      title: title,
      description: body,
      type: NotificationType.general,
      imageUrl: null,
      userId: null,
      createdAt: createdAt,
      isRead: false,
      actionId: null,
    );
  }

  NotificationModel _rowToModel(Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';
    final title = row['title']?.toString() ?? '';
    final body = row['body']?.toString() ?? '';
    final typeStr = (row['type']?.toString() ?? 'general').toLowerCase();
    final isRead = row['is_read'] as bool? ?? false;
    final createdAt = row['created_at'] != null
        ? DateTime.parse(row['created_at'] as String)
        : DateTime.now();
    final imageUrl = row['image_url']?.toString();
    final actionId = _parseActionId(row['data']);

    return NotificationModel(
      id: id,
      title: title,
      description: body,
      type: _typeFromString(typeStr),
      imageUrl: imageUrl,
      userId: null,
      createdAt: createdAt,
      isRead: isRead,
      actionId: actionId,
    );
  }

  static String? _parseActionId(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      return m['action_id']?.toString();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return decoded['action_id']?.toString();
        }
      } catch (_) {}
    }
    return null;
  }

  static NotificationType _typeFromString(String type) {
    switch (type) {
      case 'message':
        return NotificationType.message;
      case 'deal':
        return NotificationType.deal;
      case 'event':
        return NotificationType.event;
      case 'job':
        return NotificationType.job;
      case 'review':
        return NotificationType.review;
      default:
        return NotificationType.general;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    if (notificationId.startsWith(_platformIdPrefix)) return;
    await SupabaseFailureMapper.guard(() => _client
        .from(SupabaseTables.notifications)
        .update({'is_read': true})
        .eq('id', notificationId));
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await SupabaseFailureMapper.guard(() => _client
        .from(SupabaseTables.notifications)
        .update({'is_read': true})
        .eq(kNotificationsRecipientColumn, userId));
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    if (notificationId.startsWith(_platformIdPrefix)) return;
    await SupabaseFailureMapper.guard(() => _client
        .from(SupabaseTables.notifications)
        .delete()
        .eq('id', notificationId));
  }

  @override
  Future<void> updateNotification(
    String notificationId, {
    required String title,
    required String description,
  }) async {
    if (notificationId.startsWith(_platformIdPrefix)) return;
    await SupabaseFailureMapper.guard(() => _client
        .from(SupabaseTables.notifications)
        .update({'title': title, 'body': description})
        .eq('id', notificationId));
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    final res = await SupabaseFailureMapper.guard(() => _client
        .from(SupabaseTables.notifications)
        .select()
        .eq(kNotificationsRecipientColumn, userId)
        .eq('is_read', false));

    return (res as List).length;
  }
}
