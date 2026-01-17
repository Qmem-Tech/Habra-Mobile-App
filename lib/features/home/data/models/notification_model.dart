import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.description,
    required super.type,
    super.imageUrl,
    super.userId,
    required super.createdAt,
    super.isRead,
    super.actionId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: _typeFromString(json['type'] as String),
      imageUrl: json['imageUrl'] as String?,
      userId: json['userId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      actionId: json['actionId'] as String?,
    );
  }

  static NotificationType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'message':
        return NotificationType.message;
      case 'deal':
        return NotificationType.deal;
      case 'event':
        return NotificationType.event;
      case 'job':
        return NotificationType.job;
      default:
        return NotificationType.general;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'actionId': actionId,
    };
  }
}
