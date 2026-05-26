import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/job_detail.dart';
import '../repositories/jobs_repository.dart';

class GetJobDetailUseCase {
  final JobsRepository repository;

  GetJobDetailUseCase(this.repository);

  Future<Either<Failure, JobDetail>> call(String jobId) async {
    return await repository.getJobDetail(jobId);
  }
}
