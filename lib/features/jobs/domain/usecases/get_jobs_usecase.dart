import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/job_listing.dart';
import '../entities/job_filters.dart';
import '../repositories/jobs_repository.dart';

class GetJobsUseCase {
  final JobsRepository repository;

  GetJobsUseCase(this.repository);

  Future<Either<Failure, List<JobListing>>> call({
    String? location,
    JobFilters? filters,
    String? searchQuery,
    bool featuredOnly = false,
  }) async {
    return await repository.getJobs(
      location: location,
      filters: filters,
      searchQuery: searchQuery,
      featuredOnly: featuredOnly,
    );
  }
}
