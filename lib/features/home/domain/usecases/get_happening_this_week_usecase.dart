import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event.dart';
import '../repositories/home_repository.dart';

class GetHappeningThisWeekUseCase {
  final HomeRepository repository;

  GetHappeningThisWeekUseCase(this.repository);

  Future<Either<Failure, List<Event>>> call(String location) {
    return repository.getHappeningThisWeek(location);
  }
}
