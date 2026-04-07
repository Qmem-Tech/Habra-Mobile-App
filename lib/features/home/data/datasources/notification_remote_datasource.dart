import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String notificationId);
  Future<void> updateNotification(
    String notificationId, {
    required String title,
    required String description,
  });
  Future<int> getUnreadCount(String userId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    return [];
  }

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> markAllAsRead(String userId) async {}

  @override
  Future<void> deleteNotification(String notificationId) async {}

  @override
  Future<void> updateNotification(
    String notificationId, {
    required String title,
    required String description,
  }) async {}

  @override
  Future<int> getUnreadCount(String userId) async {
    return 0;
  }
}
