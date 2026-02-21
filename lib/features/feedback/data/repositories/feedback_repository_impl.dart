import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/feedback_submission.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../datasources/feedback_remote_datasource.dart';
import '../models/feedback_submission_model.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackRemoteDataSource remoteDataSource;

  FeedbackRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> submitFeedback(
      FeedbackSubmission submission) async {
    try {
      await remoteDataSource.submitFeedback(
        FeedbackSubmissionModel(type: submission.type, text: submission.text),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
