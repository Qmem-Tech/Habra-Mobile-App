import '../../domain/entities/job_detail.dart';
import '../../domain/entities/job_filters.dart';
import '../../domain/entities/job_listing.dart';
import 'mock_data/mock_jobs_data.dart';

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
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return MockJobsData.getMockJobListings(
      location: location ?? filters?.location,
      categories: filters?.categories,
      jobTypes: filters?.jobTypes,
      searchQuery: searchQuery,
      featuredOnly: featuredOnly,
    );
  }

  @override
  Future<JobDetail> getJobDetail(String jobId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return MockJobsData.getJobDetail(jobId);
  }

  @override
  Future<List<String>> getJobCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockJobsData.getJobCategories();
  }

  @override
  Future<List<String>> getJobTypes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockJobsData.getJobTypes();
  }

  @override
  Future<List<String>> getBookmarkedJobIds() async => [];

  @override
  Future<void> toggleBookmark(String jobId, bool isBookmarked) async {}
}
