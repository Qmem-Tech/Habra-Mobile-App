import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final NotificationRepository notificationRepository;

  NotificationCubit({
    required this.getNotificationsUseCase,
    required this.notificationRepository,
  }) : super(NotificationInitial());

  Future<void> loadNotifications(String userId) async {
    emit(NotificationLoading());

    final result = await getNotificationsUseCase(userId);
    result.fold(
      (failure) => emit(NotificationError(failure.message)),
      (notifications) {
        if (notifications.isEmpty) {
          emit(NotificationEmpty());
        } else {
          emit(NotificationLoaded(notifications: notifications));
        }
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final result = await notificationRepository.markAsRead(notificationId);
    result.fold(
      (failure) => null, // Could emit error state
      (_) {
        final currentState = state;
        if (currentState is NotificationLoaded) {
          final updated = currentState.notifications.map((n) {
            if (n.id == notificationId) {
              return NotificationEntity(
                id: n.id,
                title: n.title,
                description: n.description,
                type: n.type,
                imageUrl: n.imageUrl,
                userId: n.userId,
                createdAt: n.createdAt,
                isRead: true,
                actionId: n.actionId,
              );
            }
            return n;
          }).toList();
          emit(NotificationLoaded(notifications: updated));
        }
      },
    );
  }

  Future<void> markAllAsRead(String userId) async {
    final result = await notificationRepository.markAllAsRead(userId);
    result.fold(
      (failure) => null,
      (_) => loadNotifications(userId),
    );
  }
}
