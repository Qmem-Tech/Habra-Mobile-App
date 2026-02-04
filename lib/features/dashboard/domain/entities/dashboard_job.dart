import 'package:equatable/equatable.dart';

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

  const DashboardJob({
    required this.id,
    required this.title,
    required this.jobType,
    required this.location,
    required this.salaryDisplay,
    required this.viewsCount,
    required this.applicantsCount,
    required this.postedTimeAgo,
    this.employerName,
  });

  /// e.g. "12 Applicants" or "2d ago"
  String get applicantsDisplay => '$applicantsCount Applicants';
  String get postedDisplay => postedTimeAgo;

  @override
  List<Object?> get props => [
        id,
        title,
        jobType,
        location,
        salaryDisplay,
        viewsCount,
        applicantsCount,
        postedTimeAgo,
        employerName,
      ];
}
