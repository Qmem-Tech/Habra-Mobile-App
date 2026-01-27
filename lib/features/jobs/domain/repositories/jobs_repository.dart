import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/job_detail.dart';
import '../entities/job_listing.dart';
import '../entities/job_filters.dart';

abstract class JobsRepository {
  /// Get all jobs with optional filters
  Future<Either<Failure, List<JobListing>>> getJobs({
    String? location,
    JobFilters? filters,
    String? searchQuery,
    bool featuredOnly = false,
  });

  /// Get job details by ID
  Future<Either<Failure, JobDetail>> getJobDetail(String jobId);

  /// Bookmark/unbookmark a job
  Future<Either<Failure, void>> toggleBookmark(String jobId, bool isBookmarked);

  /// Get bookmarked jobs
  Future<Either<Failure, List<JobListing>>> getBookmarkedJobs();

  /// Get available job categories
  Future<Either<Failure, List<String>>> getJobCategories();

  /// Get available job types
  Future<Either<Failure, List<String>>> getJobTypes();
}
