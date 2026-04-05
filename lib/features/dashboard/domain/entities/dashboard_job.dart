import 'package:equatable/equatable.dart';

import '../../../../core/utils/job_type_format.dart';

/// Job status for dashboard display.
enum DashboardJobStatus { draft, open, closed }

/// Job post as shown on business owner dashboard (with views, applicants).
class DashboardJob extends Equatable {
  final String id;
  final String title;
  /// Display label (e.g. "Full-Time").
  final String jobType;
  /// Stored slug (e.g. `full-time`) for edit forms and API.
  final String jobTypeSlug;
  final String location;
  final String salaryDisplay;
  final int? salaryMin;
  final int? salaryMax;
  final String? description;
  final String? requirements;
  final bool isRemote;
  /// `hourly` | `yearly` when present in DB.
  final String? salaryType;
  final int viewsCount;
  final int applicantsCount;
  final String postedTimeAgo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
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
    this.jobTypeSlug = 'full-time',
    required this.location,
    required this.salaryDisplay,
    this.salaryMin,
    this.salaryMax,
    this.description,
    this.requirements,
    this.isRemote = false,
    this.salaryType,
    required this.viewsCount,
    required this.applicantsCount,
    required this.postedTimeAgo,
    this.createdAt,
    this.updatedAt,
    this.employerName,
    this.employerLogoUrl,
    this.status = DashboardJobStatus.open,
  });

  bool get isDraft => status == DashboardJobStatus.draft;

  /// e.g. "12 Applicants" or "2d ago"
  String get applicantsDisplay => '$applicantsCount Applicants';
  String get postedDisplay => postedTimeAgo;

  static String normalizeJobTypeSlug(String? raw) => jobTypeNormalizeSlug(raw);

  static String formatJobTypeLabel(String? raw) => jobTypeFormatLabel(raw);

  static String salaryLineFromMinMax(int? min, int? max) =>
      jobSalaryLineFromMinMax(min, max);

  @override
  List<Object?> get props => [
        id,
        businessId,
        title,
        jobType,
        jobTypeSlug,
        location,
        salaryDisplay,
        salaryMin,
        salaryMax,
        description,
        requirements,
        isRemote,
        salaryType,
        viewsCount,
        applicantsCount,
        postedTimeAgo,
        createdAt,
        updatedAt,
        employerName,
        employerLogoUrl,
        status,
      ];
}
