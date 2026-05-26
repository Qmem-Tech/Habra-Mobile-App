import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event_detail.dart';
import '../repositories/events_repository.dart';

class GetEventDetailUseCase {
  final EventsRepository repository;

  GetEventDetailUseCase(this.repository);

  Future<Either<Failure, EventDetail>> call(String eventId) async {
    return await repository.getEventDetail(eventId);
  }
}
