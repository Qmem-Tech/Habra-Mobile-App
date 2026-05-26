import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ticket.dart';
import '../repositories/events_repository.dart';

class GetUserTicketsUseCase {
  final EventsRepository repository;

  GetUserTicketsUseCase(this.repository);

  Future<Either<Failure, List<Ticket>>> call({bool upcomingOnly = true}) async {
    return await repository.getUserTickets(upcomingOnly: upcomingOnly);
  }
}
