import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/job_application.dart';
import '../repositories/job_applications_repository.dart';

class GetApplicationsUseCase {
  final JobApplicationsRepository repository;

  GetApplicationsUseCase(this.repository);

  Future<Either<Failure, List<JobApplication>>> call({
    bool activeOnly = false,
  }) async {
    return await repository.getApplications(activeOnly: activeOnly);
  }
}
