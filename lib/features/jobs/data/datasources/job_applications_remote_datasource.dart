import '../../domain/entities/job_application.dart';
import 'mock_data/mock_applications_data.dart';
import '../models/job_application_model.dart';
import 'mock_data/mock_jobs_data.dart';

abstract class JobApplicationsRemoteDataSource {
  Future<JobApplication> submitApplication({
    required String jobId,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? resumeUrl,
    String? coverLetter,
    Map<String, String>? screeningAnswers,
  });

  Future<List<JobApplication>> getApplications({
    bool activeOnly = false,
  });

  Future<JobApplication?> getApplicationForJob(String jobId);
}

class JobApplicationsRemoteDataSourceImpl
    implements JobApplicationsRemoteDataSource {
  @override
  Future<JobApplication> submitApplication({
    required String jobId,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? resumeUrl,
    String? coverLetter,
    Map<String, String>? screeningAnswers,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Get job details to populate application
    final jobDetail = MockJobsData.getJobDetail(jobId);

    final application = JobApplicationModel(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      jobId: jobId,
      jobTitle: jobDetail.title,
      companyName: jobDetail.companyName,
      userId: 'user_123', // Mock user ID
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      resumeUrl: resumeUrl,
      coverLetter: coverLetter,
      screeningAnswers: screeningAnswers ?? {},
      status: ApplicationStatus.pending,
      appliedDate: DateTime.now(),
    );

    return MockApplicationsData.addApplication(application);
  }

  @override
  Future<List<JobApplication>> getApplications({
    bool activeOnly = false,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return MockApplicationsData.getMockApplications(
      activeOnly: activeOnly,
    );
  }

  @override
  Future<JobApplication?> getApplicationForJob(String jobId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockApplicationsData.getApplicationForJob(jobId);
  }
}
