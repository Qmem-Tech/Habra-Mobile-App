import '../../domain/entities/job_application.dart';

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
    throw UnimplementedError(
      'Use JobApplicationsSupabaseDataSource; backend must handle submit.',
    );
  }

  @override
  Future<List<JobApplication>> getApplications({
    bool activeOnly = false,
  }) async {
    return [];
  }

  @override
  Future<JobApplication?> getApplicationForJob(String jobId) async {
    return null;
  }
}
