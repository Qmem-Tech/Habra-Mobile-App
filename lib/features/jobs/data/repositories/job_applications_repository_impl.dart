import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/job_application.dart';
import '../../domain/repositories/job_applications_repository.dart';
import '../datasources/job_applications_remote_datasource.dart';

class JobApplicationsRepositoryImpl implements JobApplicationsRepository {
  final JobApplicationsRemoteDataSource remoteDataSource;

  JobApplicationsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, JobApplication>> submitApplication({
    required String jobId,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? resumeUrl,
    String? coverLetter,
    Map<String, String>? screeningAnswers,
  }) async {
    try {
      final application = await remoteDataSource.submitApplication(
        jobId: jobId,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        resumeUrl: resumeUrl,
        coverLetter: coverLetter,
        screeningAnswers: screeningAnswers,
      );
      return Right(application);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<JobApplication>>> getApplications({
    bool activeOnly = false,
  }) async {
    try {
      final applications = await remoteDataSource.getApplications(
        activeOnly: activeOnly,
      );
      return Right(applications);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, JobApplication>> getApplication(
      String applicationId) async {
    try {
      final applications = await remoteDataSource.getApplications();
      final application = applications.firstWhere(
        (app) => app.id == applicationId,
        orElse: () => throw Exception('Application not found'),
      );
      return Right(application);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, JobApplication?>> getApplicationForJob(
      String jobId) async {
    try {
      final application = await remoteDataSource.getApplicationForJob(jobId);
      return Right(application);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
