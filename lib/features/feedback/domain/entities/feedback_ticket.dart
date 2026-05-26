import 'package:equatable/equatable.dart';

enum FeedbackTicketStatus { open, inProgress, resolved }

class FeedbackTicket extends Equatable {
  final String id;
  final String userId;
  final String type;
  final String text;
  final DateTime createdAt;
  final FeedbackTicketStatus status;
  final String? adminNotes;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? submitterName;
  final String? submitterEmail;

  const FeedbackTicket({
    required this.id,
    required this.userId,
    required this.type,
    required this.text,
    required this.createdAt,
    required this.status,
    this.adminNotes,
    this.resolvedAt,
    this.resolvedBy,
    this.submitterName,
    this.submitterEmail,
  });

  @override
  List<Object?> get props => [id, userId, status, createdAt];
}
