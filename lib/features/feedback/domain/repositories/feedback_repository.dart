import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/feedback_submission.dart';

abstract class FeedbackRepository {
  Future<Either<Failure, void>> submitFeedback(FeedbackSubmission submission);
}
