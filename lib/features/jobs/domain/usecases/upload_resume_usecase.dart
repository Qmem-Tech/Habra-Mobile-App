import 'dart:io';

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/job_applications_repository.dart';

class UploadResumeUseCase {
  final JobApplicationsRepository repository;

  UploadResumeUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String userId,
    required String jobId,
    required File file,
  }) async {
    return await repository.uploadResume(userId, jobId, file);
  }
}
