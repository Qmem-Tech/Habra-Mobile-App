import 'package:equatable/equatable.dart';
import '../../domain/entities/applicant_detail.dart';
import '../../domain/entities/business_review.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/dashboard_deal.dart';
import '../../domain/entities/dashboard_job.dart';
import '../../domain/entities/job_applicant.dart';
import '../../domain/entities/owner_upcoming_event.dart';
import '../../domain/repositories/dashboard_repository.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardTabState extends DashboardState {
  final DashboardAnalytics? analytics;
  final List<DashboardDeal> deals;
  final DashboardDealStatus? dealsFilter;
  final List<DashboardJob> jobs;
  final DashboardJobStatus? jobsFilter;
  final RatingOverview? reviewsOverview;
  final List<BusinessReview> reviews;
  /// Backing field; use [upcomingEvents] so UI never sees null (hot reload / copyWith safe).
  final List<OwnerUpcomingEvent>? _upcomingEvents;
  final String? errorMessage;

  /// Organizer events for the dashboard; empty when none loaded.
  List<OwnerUpcomingEvent> get upcomingEvents =>
      _upcomingEvents ?? const [];

  const DashboardTabState({
    this.analytics,
    this.deals = const [],
    this.dealsFilter,
    this.jobs = const [],
    this.jobsFilter,
    this.reviewsOverview,
    this.reviews = const [],
    List<OwnerUpcomingEvent>? upcomingEvents,
    this.errorMessage,
  }) : _upcomingEvents = upcomingEvents;

  int get activeDealsCount =>
      deals.where((d) => d.status == DashboardDealStatus.active).length;
  int get expiredDealsCount =>
      deals.where((d) => d.status == DashboardDealStatus.expired).length;
  int get draftDealsCount =>
      deals.where((d) => d.status == DashboardDealStatus.draft).length;

  int get activeJobsCount =>
      jobs.where((j) => j.status == DashboardJobStatus.open).length;
  int get draftJobsCount =>
      jobs.where((j) => j.status == DashboardJobStatus.draft).length;

  @override
  List<Object?> get props => [
        analytics,
        deals,
        dealsFilter,
        jobs,
        jobsFilter,
        reviewsOverview,
        reviews,
        _upcomingEvents,
        errorMessage,
      ];

  DashboardTabState copyWith({
    DashboardAnalytics? analytics,
    List<DashboardDeal>? deals,
    DashboardDealStatus? dealsFilter,
    List<DashboardJob>? jobs,
    DashboardJobStatus? jobsFilter,
    RatingOverview? reviewsOverview,
    List<BusinessReview>? reviews,
    List<OwnerUpcomingEvent>? upcomingEvents,
    String? errorMessage,
  }) {
    return DashboardTabState(
      analytics: analytics ?? this.analytics,
      deals: deals ?? this.deals,
      dealsFilter: dealsFilter ?? this.dealsFilter,
      jobs: jobs ?? this.jobs,
      jobsFilter: jobsFilter ?? this.jobsFilter,
      reviewsOverview: reviewsOverview ?? this.reviewsOverview,
      reviews: reviews ?? this.reviews,
      upcomingEvents: upcomingEvents ?? _upcomingEvents ?? const [],
      errorMessage: errorMessage,
    );
  }
}

class ApplicantsLoading extends DashboardState {}

class ApplicantsLoaded extends DashboardState {
  final String jobId;
  final String jobTitle;
  final String jobSubtitle;
  final List<JobApplicant> applicants;
  final ApplicantStatus? filter;

  const ApplicantsLoaded({
    required this.jobId,
    required this.jobTitle,
    required this.jobSubtitle,
    required this.applicants,
    this.filter,
  });

  @override
  List<Object?> get props => [jobId, jobTitle, jobSubtitle, applicants, filter];
}

class ApplicantDetailLoading extends DashboardState {}

class ApplicantDetailLoaded extends DashboardState {
  final ApplicantDetail detail;

  const ApplicantDetailLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

class ApplicantDetailError extends DashboardState {
  final String message;

  const ApplicantDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
