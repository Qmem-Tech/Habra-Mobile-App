import '../../domain/entities/job_detail.dart';
import '../../domain/entities/job_filters.dart';
import '../../domain/entities/job_listing.dart';

abstract class JobsRemoteDataSource {
  Future<List<JobListing>> getJobs({
    String? location,
    JobFilters? filters,
    String? searchQuery,
    bool featuredOnly = false,
  });

  Future<JobDetail> getJobDetail(String jobId);

  Future<List<String>> getJobCategories();

  Future<List<String>> getJobTypes();

  /// Bookmarked job IDs for the current user (from backend when using Supabase).
  Future<List<String>> getBookmarkedJobIds();

  Future<void> toggleBookmark(String jobId, bool isBookmarked);
}

class JobsRemoteDataSourceImpl implements JobsRemoteDataSource {
  @override
  Future<List<JobListing>> getJobs({
    String? location,
    JobFilters? filters,
    String? searchQuery,
    bool featuredOnly = false,
  }) async {
    return [];
  }

  @override
  Future<JobDetail> getJobDetail(String jobId) async {
    throw UnimplementedError(
      'Use JobsSupabaseDataSource; backend must provide job detail for $jobId',
    );
  }

  @override
  Future<List<String>> getJobCategories() async {
    return [];
  }

  @override
  Future<List<String>> getJobTypes() async {
    return [];
  }

  @override
  Future<List<String>> getBookmarkedJobIds() async => [];

  @override
  Future<void> toggleBookmark(String jobId, bool isBookmarked) async {}
}
