import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_events_usecase.dart';
import '../../domain/usecases/get_event_detail_usecase.dart';
import '../../domain/entities/event_filters.dart';
import 'events_state.dart';

class EventsCubit extends Cubit<EventsState> {
  final GetEventsUseCase getEventsUseCase;
  final GetEventDetailUseCase getEventDetailUseCase;

  EventsCubit({
    required this.getEventsUseCase,
    required this.getEventDetailUseCase,
  }) : super(EventsInitial());

  Future<void> loadEvents({
    String? location,
    EventFilters? filters,
    String? searchQuery,
  }) async {
    if (isClosed) return;
    emit(EventsLoading());

    final result = await getEventsUseCase(
      location: location,
      filters: filters,
      searchQuery: searchQuery,
    );

    result.fold(
      (failure) {
        if (!isClosed) emit(EventsError(failure.message));
      },
      (events) {
        if (!isClosed) {
          emit(EventsLoaded(
            events: events,
            activeFilters: filters,
            searchQuery: searchQuery,
          ));
        }
      },
    );
  }

  Future<void> loadEventDetail(String eventId) async {
    if (isClosed) return;
    emit(EventDetailLoading());

    final result = await getEventDetailUseCase(eventId);

    result.fold(
      (failure) {
        if (!isClosed) emit(EventDetailError(failure.message));
      },
      (event) async {
        // Load similar events
        final similarResult = await getEventsUseCase();
        if (isClosed) return;
        similarResult.fold(
          (_) {
            if (!isClosed) {
              emit(EventDetailLoaded(event: event, similarEvents: []));
            }
          },
          (similarEvents) {
            if (!isClosed) {
              emit(EventDetailLoaded(
                event: event,
                similarEvents: similarEvents
                    .where((e) => e.id != eventId)
                    .take(2)
                    .toList(),
              ));
            }
          },
        );
      },
    );
  }
}
