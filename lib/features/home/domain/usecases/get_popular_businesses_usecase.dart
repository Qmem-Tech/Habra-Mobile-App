import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/business.dart';
import '../home_feed_location.dart';
import '../repositories/home_repository.dart';

class GetPopularBusinessesUseCase {
  final HomeRepository repository;

  GetPopularBusinessesUseCase(this.repository);

  Future<Either<Failure, List<Business>>> call(HomeFeedLocation location) {
    return repository.getPopularBusinesses(location);
  }
}
