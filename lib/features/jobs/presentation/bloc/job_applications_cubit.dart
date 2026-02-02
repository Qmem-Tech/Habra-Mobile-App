import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/submit_application_usecase.dart';
import '../../domain/usecases/get_applications_usecase.dart';
import 'job_applications_state.dart';

class JobApplicationsCubit extends Cubit<JobApplicationsState> {
  final SubmitApplicationUseCase submitApplicationUseCase;
  final GetApplicationsUseCase getApplicationsUseCase;

  JobApplicationsCubit({
    required this.submitApplicationUseCase,
    required this.getApplicationsUseCase,
  }) : super(JobApplicationsInitial());

  Future<void> loadApplications({bool activeOnly = false}) async {
    emit(JobApplicationsLoading());

    final result = await getApplicationsUseCase(activeOnly: activeOnly);

    result.fold(
      (failure) => emit(JobApplicationsError(failure.message)),
      (applications) {
        final activeApplications = applications
            .where((app) => app.isActive)
            .toList()
          ..sort((a, b) => b.appliedDate.compareTo(a.appliedDate));

        final closedApplications = applications
            .where((app) => app.isClosed)
            .toList()
          ..sort((a, b) => b.appliedDate.compareTo(a.appliedDate));

        emit(JobApplicationsLoaded(
          applications: applications,
          activeApplications: activeApplications,
          closedApplications: closedApplications,
          activeTabSelected: activeOnly,
        ));
      },
    );
  }

  Future<void> submitApplication({
    required String jobId,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? resumeUrl,
    String? coverLetter,
    Map<String, String>? screeningAnswers,
  }) async {
    emit(SubmitApplicationLoading());

    final result = await submitApplicationUseCase(
      jobId: jobId,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      resumeUrl: resumeUrl,
      coverLetter: coverLetter,
      screeningAnswers: screeningAnswers,
    );

    result.fold(
      (failure) => emit(SubmitApplicationError(failure.message)),
      (application) => emit(SubmitApplicationSuccess(application)),
    );
  }
}
