import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event_list_item.dart';
import '../entities/event_filters.dart';
import '../repositories/events_repository.dart';

class GetEventsUseCase {
  final EventsRepository repository;

  GetEventsUseCase(this.repository);

  Future<Either<Failure, List<EventListItem>>> call({
    String? location,
    EventFilters? filters,
    String? searchQuery,
  }) async {
    return await repository.getEvents(
      location: location,
      filters: filters,
      searchQuery: searchQuery,
    );
  }
}
