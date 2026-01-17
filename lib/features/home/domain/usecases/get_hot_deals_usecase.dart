import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/deal.dart';
import '../repositories/home_repository.dart';

class GetHotDealsUseCase {
  final HomeRepository repository;

  GetHotDealsUseCase(this.repository);

  Future<Either<Failure, List<Deal>>> call(String location) {
    return repository.getHotDealsNearYou(location);
  }
}
