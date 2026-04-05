import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/application_experience_entry.dart';
import '../entities/job_application.dart';
import '../repositories/job_applications_repository.dart';

class SubmitApplicationUseCase {
  final JobApplicationsRepository repository;

  SubmitApplicationUseCase(this.repository);

  Future<Either<Failure, JobApplication>> call({
    required String jobId,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? resumeUrl,
    String? coverLetter,
    String? photoUrl,
    Map<String, String>? screeningAnswers,
    List<ApplicationExperienceEntry>? workExperience,
  }) async {
    return await repository.submitApplication(
      jobId: jobId,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      resumeUrl: resumeUrl,
      coverLetter: coverLetter,
      photoUrl: photoUrl,
      screeningAnswers: screeningAnswers,
      workExperience: workExperience,
    );
  }
}
