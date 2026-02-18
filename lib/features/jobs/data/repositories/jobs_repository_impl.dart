import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/job_detail.dart';
import '../../domain/entities/job_filters.dart';
import '../../domain/entities/job_listing.dart';
import '../../domain/repositories/jobs_repository.dart';
import '../datasources/jobs_remote_datasource.dart';
import '../datasources/jobs_local_datasource.dart';

class JobsRepositoryImpl implements JobsRepository {
  final JobsRemoteDataSource remoteDataSource;
  final JobsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  JobsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<JobListing>>> getJobs({
    String? location,
    JobFilters? filters,
    String? searchQuery,
    bool featuredOnly = false,
  }) async {
    try {
      final jobs = await remoteDataSource.getJobs(
        location: location,
        filters: filters,
        searchQuery: searchQuery,
        featuredOnly: featuredOnly,
      );

      // Load bookmarks from remote (Supabase) or local cache
      final bookmarkedIds = await remoteDataSource.getBookmarkedJobIds();
      final ids = bookmarkedIds.isNotEmpty
          ? bookmarkedIds
          : await localDataSource.getBookmarkedJobIds();
      final jobsWithBookmarks = jobs.map((job) {
        return JobListing(
          id: job.id,
          title: job.title,
          companyName: job.companyName,
          companyLogoUrl: job.companyLogoUrl,
          jobType: job.jobType,
          salary: job.salary,
          location: job.location,
          postedDate: job.postedDate,
          category: job.category,
          isFeatured: job.isFeatured,
          isBookmarked: ids.contains(job.id),
        );
      }).toList();

      return Right(jobsWithBookmarks);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, JobDetail>> getJobDetail(String jobId) async {
    try {
      final jobDetail = await remoteDataSource.getJobDetail(jobId);
      return Right(jobDetail);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleBookmark(
      String jobId, bool isBookmarked) async {
    try {
      await remoteDataSource.toggleBookmark(jobId, isBookmarked);
      await localDataSource.toggleBookmark(jobId, isBookmarked);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<JobListing>>> getBookmarkedJobs() async {
    try {
      final bookmarkedIds = await remoteDataSource.getBookmarkedJobIds();
      final ids = bookmarkedIds.isNotEmpty
          ? bookmarkedIds
          : await localDataSource.getBookmarkedJobIds();
      if (ids.isEmpty) return const Right([]);

      // Get all jobs and filter by bookmarked IDs
      final allJobs = await remoteDataSource.getJobs();
      final bookmarkedJobs = allJobs
          .where((job) => ids.contains(job.id))
          .map((job) => JobListing(
                id: job.id,
                title: job.title,
                companyName: job.companyName,
                companyLogoUrl: job.companyLogoUrl,
                jobType: job.jobType,
                salary: job.salary,
                location: job.location,
                postedDate: job.postedDate,
                category: job.category,
                isFeatured: job.isFeatured,
                isBookmarked: true,
              ))
          .toList();

      return Right(bookmarkedJobs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getJobCategories() async {
    try {
      final categories = await remoteDataSource.getJobCategories();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getJobTypes() async {
    try {
      final types = await remoteDataSource.getJobTypes();
      return Right(types);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
