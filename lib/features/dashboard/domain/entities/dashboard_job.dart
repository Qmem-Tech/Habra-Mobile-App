import 'package:equatable/equatable.dart';

/// Job status for dashboard display.
enum DashboardJobStatus { draft, open, closed }

/// Job post as shown on business owner dashboard (with views, applicants).
class DashboardJob extends Equatable {
  final String id;
  final String title;
  final String jobType;
  final String location;
  final String salaryDisplay;
  final int viewsCount;
  final int applicantsCount;
  final String postedTimeAgo;
  /// Employer/business name for display (e.g. in Select Job to Boost).
  final String? employerName;
  /// Business logo/avatar URL for display in job cards.
  final String? employerLogoUrl;
  final DashboardJobStatus status;
  /// Owning business (required for `boosts.business_id` when boosting this job).
  final String businessId;

  const DashboardJob({
    required this.id,
    required this.businessId,
    required this.title,
    required this.jobType,
    required this.location,
    required this.salaryDisplay,
    required this.viewsCount,
    required this.applicantsCount,
    required this.postedTimeAgo,
    this.employerName,
    this.employerLogoUrl,
    this.status = DashboardJobStatus.open,
  });

  bool get isDraft => status == DashboardJobStatus.draft;

  /// e.g. "12 Applicants" or "2d ago"
  String get applicantsDisplay => '$applicantsCount Applicants';
  String get postedDisplay => postedTimeAgo;

  @override
  List<Object?> get props => [
        id,
        businessId,
        title,
        jobType,
        location,
        salaryDisplay,
        viewsCount,
        applicantsCount,
        postedTimeAgo,
        employerName,
        employerLogoUrl,
        status,
      ];
}
