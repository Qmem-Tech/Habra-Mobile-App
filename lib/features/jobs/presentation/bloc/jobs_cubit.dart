import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/job_filters.dart';
import '../../domain/usecases/get_jobs_usecase.dart';
import '../../domain/usecases/get_job_detail_usecase.dart';
import '../../domain/usecases/toggle_bookmark_usecase.dart';
import '../../domain/usecases/get_job_categories_usecase.dart';
import 'jobs_state.dart';

class JobsCubit extends Cubit<JobsState> {
  final GetJobsUseCase getJobsUseCase;
  final GetJobDetailUseCase getJobDetailUseCase;
  final ToggleBookmarkUseCase toggleBookmarkUseCase;
  final GetJobCategoriesUseCase getJobCategoriesUseCase;

  JobsCubit({
    required this.getJobsUseCase,
    required this.getJobDetailUseCase,
    required this.toggleBookmarkUseCase,
    required this.getJobCategoriesUseCase,
  }) : super(JobsInitial());

  Future<void> loadJobs({
    String? location,
    JobFilters? filters,
    String? searchQuery,
  }) async {
    emit(JobsLoading());

    final result = await getJobsUseCase(
      location: location,
      filters: filters,
      searchQuery: searchQuery,
      featuredOnly: false,
    );

    result.fold(
      (failure) => emit(JobsError(failure.message)),
      (jobs) {
        final featuredJobs = jobs.where((job) => job.isFeatured).toList();
        final recentJobs = jobs
            .where((job) => !job.isFeatured)
            .toList()
          ..sort((a, b) {
            if (a.postedDate == null || b.postedDate == null) return 0;
            return b.postedDate!.compareTo(a.postedDate!);
          });

        emit(JobsLoaded(
          jobs: jobs,
          featuredJobs: featuredJobs,
          recentJobs: recentJobs,
          activeFilters: filters,
          searchQuery: searchQuery,
          location: location,
        ));
      },
    );
  }

  Future<void> loadJobDetail(String jobId) async {
    emit(JobDetailLoading());

    final result = await getJobDetailUseCase(jobId);

    result.fold(
      (failure) => emit(JobDetailError(failure.message)),
      (jobDetail) => emit(JobDetailLoaded(jobDetail)),
    );
  }

  Future<void> toggleBookmark(String jobId, bool isBookmarked) async {
    final result = await toggleBookmarkUseCase(jobId, isBookmarked);

    result.fold(
      (failure) {
        // Handle error silently or show snackbar
      },
      (_) {
        // Reload jobs to reflect bookmark changes
        if (state is JobsLoaded) {
          final currentState = state as JobsLoaded;
          loadJobs(
            location: currentState.location,
            filters: currentState.activeFilters,
            searchQuery: currentState.searchQuery,
          );
        }
      },
    );
  }

  Future<void> loadJobCategories() async {
    final result = await getJobCategoriesUseCase();

    result.fold(
      (failure) {
        // Handle error
      },
      (categories) => emit(JobCategoriesLoaded(categories)),
    );
  }
}
