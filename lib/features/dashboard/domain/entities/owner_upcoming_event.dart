import 'package:equatable/equatable.dart';

/// Upcoming event row for organizer home / activity (from `events`).
class OwnerUpcomingEvent extends Equatable {
  const OwnerUpcomingEvent({
    required this.id,
    required this.title,
    required this.startAt,
  });

  final String id;
  final String title;
  final DateTime startAt;

  @override
  List<Object?> get props => [id, title, startAt];
}
