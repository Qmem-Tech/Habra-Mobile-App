import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/job.dart';
import '../repositories/home_repository.dart';

class GetLatestJobsUseCase {
  final HomeRepository repository;

  GetLatestJobsUseCase(this.repository);

  Future<Either<Failure, List<Job>>> call(String location) {
    return repository.getLatestJobs(location);
  }
}
