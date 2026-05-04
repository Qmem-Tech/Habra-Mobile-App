import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/events_repository.dart';

class CancelUnpaidEventOrderUseCase {
  final EventsRepository repository;

  CancelUnpaidEventOrderUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String orderId) {
    return repository.cancelUnpaidEventOrder(orderId);
  }
}
