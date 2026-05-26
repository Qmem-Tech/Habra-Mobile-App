import 'package:equatable/equatable.dart';
import '../../domain/entities/event_list_item.dart';
import '../../domain/entities/event_detail.dart';
import '../../domain/entities/event_filters.dart';

abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {}

class EventsLoading extends EventsState {}

class EventsLoaded extends EventsState {
  final List<EventListItem> events;
  final EventFilters? activeFilters;
  final String? searchQuery;

  const EventsLoaded({
    required this.events,
    this.activeFilters,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [events, activeFilters, searchQuery];
}

class EventsError extends EventsState {
  final String message;

  const EventsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Event Detail States
class EventDetailInitial extends EventsState {}

class EventDetailLoading extends EventsState {}

class EventDetailLoaded extends EventsState {
  final EventDetail event;
  final List<EventListItem> similarEvents;

  const EventDetailLoaded({
    required this.event,
    required this.similarEvents,
  });

  @override
  List<Object?> get props => [event, similarEvents];
}

class EventDetailError extends EventsState {
  final String message;

  const EventDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
