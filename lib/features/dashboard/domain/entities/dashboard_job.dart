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

  const DashboardJob({
    required this.id,
    required this.title,
    required this.jobType,
    required this.location,
    required this.salaryDisplay,
    required this.viewsCount,
    required this.applicantsCount,
    required this.postedTimeAgo,
  });

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
      ];
}
