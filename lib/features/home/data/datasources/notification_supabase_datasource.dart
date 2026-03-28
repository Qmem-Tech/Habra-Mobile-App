import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';
import 'notification_remote_datasource.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';

/// Supabase implementation of [NotificationRemoteDataSource].
/// Uses public.notifications table.
class NotificationSupabaseDataSource implements NotificationRemoteDataSource {
  NotificationSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    final res = await SupabaseFailureMapper.guard(() => _client
        .from(SupabaseTables.notifications)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100));

    final list = res as List<dynamic>;
    return list
        .map((e) => _rowToModel(Map<String, dynamic>.from(e as Map)))
        .toList();
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
        .eq('user_id', userId));
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    final res = await SupabaseFailureMapper.guard(() => _client
        .from(SupabaseTables.notifications)
        .select()
        .eq('user_id', userId)
        .eq('is_read', false));

    return (res as List).length;
  }
}
