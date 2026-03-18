import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event_detail.dart';
import '../entities/create_event_data.dart';
import '../repositories/events_repository.dart';

class CreateEventUseCase {
  final EventsRepository repository;

  CreateEventUseCase(this.repository);

  Future<Either<Failure, EventDetail>> call(CreateEventData data) async {
    return await repository.createEvent(data);
  }
}
