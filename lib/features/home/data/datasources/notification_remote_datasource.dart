import '../models/notification_model.dart';
import 'mock_data/mock_notification_data.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<int> getUnreadCount(String userId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  // TODO: Replace with Firebase/API calls
  // Currently using mock data for UI/UX testing

  static final List<NotificationModel> _mockNotifications = [];

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    _mockNotifications.clear();
    _mockNotifications.addAll(MockNotificationData.getMockNotifications(userId));
    return List.from(_mockNotifications);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final notification = _mockNotifications[index];
      _mockNotifications[index] = NotificationModel(
        id: notification.id,
        title: notification.title,
        description: notification.description,
        type: notification.type,
        imageUrl: notification.imageUrl,
        userId: notification.userId,
        createdAt: notification.createdAt,
        isRead: true,
        actionId: notification.actionId,
      );
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (int i = 0; i < _mockNotifications.length; i++) {
      final notification = _mockNotifications[i];
      _mockNotifications[i] = NotificationModel(
        id: notification.id,
        title: notification.title,
        description: notification.description,
        type: notification.type,
        imageUrl: notification.imageUrl,
        userId: notification.userId,
        createdAt: notification.createdAt,
        isRead: true,
        actionId: notification.actionId,
      );
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockNotifications.where((n) => !n.isRead).length;
  }
}
