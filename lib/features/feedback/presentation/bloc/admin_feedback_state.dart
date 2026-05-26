import 'package:equatable/equatable.dart';

import '../../domain/entities/feedback_ticket.dart';

abstract class AdminFeedbackState extends Equatable {
  const AdminFeedbackState();

  @override
  List<Object?> get props => [];
}

class AdminFeedbackInitial extends AdminFeedbackState {}

class AdminFeedbackLoading extends AdminFeedbackState {}

class AdminFeedbackLoaded extends AdminFeedbackState {
  final List<FeedbackTicket> items;

  const AdminFeedbackLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class AdminFeedbackError extends AdminFeedbackState {
  final String message;

  const AdminFeedbackError(this.message);

  @override
  List<Object?> get props => [message];
}
