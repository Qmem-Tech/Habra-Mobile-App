import 'package:equatable/equatable.dart';
import '../../domain/entities/job_detail.dart';
import '../../domain/entities/job_listing.dart';
import '../../domain/entities/job_filters.dart';

abstract class JobsState extends Equatable {
  const JobsState();

  @override
  List<Object?> get props => [];
}

class JobsInitial extends JobsState {}

class JobsLoading extends JobsState {}

class JobsLoaded extends JobsState {
  final List<JobListing> jobs;
  final List<JobListing> featuredJobs;
  final List<JobListing> recentJobs;
  final JobFilters? activeFilters;
  final String? searchQuery;
  final String? location;

  const JobsLoaded({
    required this.jobs,
    required this.featuredJobs,
    required this.recentJobs,
    this.activeFilters,
    this.searchQuery,
    this.location,
  });

  @override
  List<Object?> get props => [
        jobs,
        featuredJobs,
        recentJobs,
        activeFilters,
        searchQuery,
        location,
      ];
}

class JobsError extends JobsState {
  final String message;

  const JobsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Job Detail States
class JobDetailInitial extends JobsState {}

class JobDetailLoading extends JobsState {}

class JobDetailLoaded extends JobsState {
  final JobDetail jobDetail;

  const JobDetailLoaded(this.jobDetail);

  @override
  List<Object?> get props => [jobDetail];
}

class JobDetailError extends JobsState {
  final String message;

  const JobDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// Categories States
class JobCategoriesLoaded extends JobsState {
  final List<String> categories;

  const JobCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}
