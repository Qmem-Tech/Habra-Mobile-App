import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/create_event_data.dart';
import '../entities/event_detail.dart';
import '../repositories/events_repository.dart';

class UpdateEventUseCase {
  UpdateEventUseCase(this._repository);

  final EventsRepository _repository;

  Future<Either<Failure, EventDetail>> call(
    String eventId,
    CreateEventData data,
  ) {
    return _repository.updateEvent(eventId, data);
  }
}
