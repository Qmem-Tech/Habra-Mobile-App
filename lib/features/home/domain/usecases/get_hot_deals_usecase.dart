import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/deal.dart';
import '../home_feed_location.dart';
import '../repositories/home_repository.dart';

class GetHotDealsUseCase {
  final HomeRepository repository;

  GetHotDealsUseCase(this.repository);

  Future<Either<Failure, List<Deal>>> call(HomeFeedLocation location) {
    return repository.getHotDealsNearYou(location);
  }
}
