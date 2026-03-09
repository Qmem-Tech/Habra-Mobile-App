import 'dart:io';

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/job_application.dart';

abstract class JobApplicationsRepository {
  /// Upload resume file. Returns public URL.
  Future<Either<Failure, String>> uploadResume(String userId, String jobId, File file);

  /// Submit a job application
  Future<Either<Failure, JobApplication>> submitApplication({
    required String jobId,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? resumeUrl,
    String? coverLetter,
    Map<String, String>? screeningAnswers,
  });

  /// Get user's applications
  Future<Either<Failure, List<JobApplication>>> getApplications({
    bool activeOnly = false,
  });

  /// Get application by ID
  Future<Either<Failure, JobApplication>> getApplication(String applicationId);

  /// Get application status for a job
  Future<Either<Failure, JobApplication?>> getApplicationForJob(String jobId);
}
