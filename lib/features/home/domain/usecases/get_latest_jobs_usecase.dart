import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/job.dart';
import '../home_feed_location.dart';
import '../repositories/home_repository.dart';

class GetLatestJobsUseCase {
  final HomeRepository repository;

  GetLatestJobsUseCase(this.repository);

  Future<Either<Failure, List<Job>>> call(HomeFeedLocation location) {
    return repository.getLatestJobs(location);
  }
}
