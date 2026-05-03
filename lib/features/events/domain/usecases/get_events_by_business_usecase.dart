import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event_list_item.dart';
import '../repositories/events_repository.dart';

class GetEventsByBusinessUseCase {
  final EventsRepository repository;

  GetEventsByBusinessUseCase(this.repository);

  Future<Either<Failure, List<EventListItem>>> call(String businessId) async {
    return repository.getEventsByBusinessId(businessId);
  }
}
