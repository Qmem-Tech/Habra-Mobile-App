import 'package:equatable/equatable.dart';
import '../../domain/entities/job_application.dart';

abstract class JobApplicationsState extends Equatable {
  const JobApplicationsState();

  @override
  List<Object?> get props => [];
}

class JobApplicationsInitial extends JobApplicationsState {}

class JobApplicationsLoading extends JobApplicationsState {}

class JobApplicationsLoaded extends JobApplicationsState {
  final List<JobApplication> applications;
  final List<JobApplication> activeApplications;
  final List<JobApplication> closedApplications;
  final bool activeTabSelected;

  const JobApplicationsLoaded({
    required this.applications,
    required this.activeApplications,
    required this.closedApplications,
    this.activeTabSelected = true,
  });

  @override
  List<Object?> get props => [
        applications,
        activeApplications,
        closedApplications,
        activeTabSelected,
      ];
}

class JobApplicationsError extends JobApplicationsState {
  final String message;

  const JobApplicationsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Submit Application States
class SubmitApplicationInitial extends JobApplicationsState {}

class SubmitApplicationLoading extends JobApplicationsState {}

class SubmitApplicationSuccess extends JobApplicationsState {
  final JobApplication application;

  const SubmitApplicationSuccess(this.application);

  @override
  List<Object?> get props => [application];
}

class SubmitApplicationError extends JobApplicationsState {
  final String message;

  const SubmitApplicationError(this.message);

  @override
  List<Object?> get props => [message];
}
