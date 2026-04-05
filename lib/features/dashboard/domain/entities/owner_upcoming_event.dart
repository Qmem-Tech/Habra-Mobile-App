import 'package:equatable/equatable.dart';

/// Organizer event row for home activity and dashboard lists (from `events`).
class OwnerUpcomingEvent extends Equatable {
  OwnerUpcomingEvent({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.imageUrl,
    bool? isPublished,
  }) : _isPublished = isPublished;

  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String? imageUrl;
  /// `events.is_active` — when false, treat as draft (not shown publicly).
  /// Null is treated as published so the UI never crashes on legacy or partial rows.
  final bool? _isPublished;

  bool get isPublished => _isPublished ?? true;

  /// Published and end time has passed.
  bool get isPast => isPublished && endAt.isBefore(DateTime.now());

  /// Published and not yet ended (upcoming or in progress).
  bool get isActiveListing => isPublished && !isPast;

  bool get isDraft => !isPublished;

  @override
  List<Object?> get props => [id, title, startAt, endAt, imageUrl, _isPublished];
}
