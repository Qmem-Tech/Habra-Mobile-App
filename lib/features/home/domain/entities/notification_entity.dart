import 'package:equatable/equatable.dart';

enum NotificationType {
  message,
  deal,
  event,
  job,
  general,
}

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final NotificationType type;
  final String? imageUrl;
  final String? userId; // For message notifications
  final DateTime createdAt;
  final bool isRead;
  final String? actionId; // ID of related item (event, deal, job, etc.)

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.imageUrl,
    this.userId,
    required this.createdAt,
    this.isRead = false,
    this.actionId,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        imageUrl,
        userId,
        createdAt,
        isRead,
        actionId,
      ];
}
