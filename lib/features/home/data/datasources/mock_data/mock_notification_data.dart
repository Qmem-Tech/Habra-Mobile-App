import '../../models/notification_model.dart';
import '../../../domain/entities/notification_entity.dart';

class MockNotificationData {
  static List<NotificationModel> getMockNotifications(String userId) {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'n1',
        title: 'Selam sent you a messa...',
        description: 'Hey, are you going to the coffee ceremony tomorrow at Bole Medhanialem?',
        type: NotificationType.message,
        imageUrl: 'https://picsum.photos/100/100?random=12',
        userId: 'u2',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      NotificationModel(
        id: 'n2',
        title: 'Abebe sent you a messa...',
        description: 'Hey, are you going to the coffee ceremony tomorrow at Bole Medhanialem?',
        type: NotificationType.message,
        imageUrl: 'https://picsum.photos/100/100?random=13',
        userId: 'u3',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      NotificationModel(
        id: 'n3',
        title: 'New Deal: Buna Cafe',
        description: 'Get 20% off all traditional breakfast items this weekend only. Bring a friend!',
        type: NotificationType.deal,
        imageUrl: 'https://picsum.photos/100/100?random=14',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: false,
        actionId: 'd2',
      ),
      NotificationModel(
        id: 'n4',
        title: 'Jazz Night at Fendika',
        description: 'Don\'t miss the live performance by the Ethio-Jazz band starting at 8 PM.',
        type: NotificationType.event,
        imageUrl: 'https://picsum.photos/100/100?random=15',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: false,
        actionId: 'e4',
      ),
      NotificationModel(
        id: 'n5',
        title: 'New Job Alert',
        description: 'Senior Software Developer role posted by TechAddis. Matches your profile.',
        type: NotificationType.job,
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: false,
        actionId: 'j4',
      ),
    ];
  }
}
