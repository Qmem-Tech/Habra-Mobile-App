import 'dart:io';

import '../../domain/entities/job_application.dart';

abstract class JobApplicationsRemoteDataSource {
  /// Upload resume to storage. Returns public URL.
  Future<String> uploadResume(String userId, String jobId, File file);

  Future<JobApplication> submitApplication({
    required String jobId,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? resumeUrl,
    String? coverLetter,
    String? photoUrl,
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
  Future<String> uploadResume(String userId, String jobId, File file) async {
    throw UnimplementedError('Use JobApplicationsSupabaseDataSource');
  }

  @override
  Future<JobApplication> submitApplication({
    required String jobId,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? resumeUrl,
    String? coverLetter,
    String? photoUrl,
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
