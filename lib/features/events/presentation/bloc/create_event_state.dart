import 'package:equatable/equatable.dart';
import '../../domain/entities/event_detail.dart';

sealed class CreateEventState extends Equatable {
  const CreateEventState();

  @override
  List<Object?> get props => [];
}

final class CreateEventInitial extends CreateEventState {}

final class CreateEventLoading extends CreateEventState {}

final class CreateEventSuccess extends CreateEventState {
  const CreateEventSuccess(this.event);

  final EventDetail event;

  @override
  List<Object?> get props => [event];
}

final class CreateEventError extends CreateEventState {
  const CreateEventError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
