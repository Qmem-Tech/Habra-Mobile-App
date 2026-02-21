import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/feedback_submission.dart';
import '../repositories/feedback_repository.dart';

class SubmitFeedbackUseCase {
  final FeedbackRepository repository;

  SubmitFeedbackUseCase(this.repository);

  Future<Either<Failure, void>> call(FeedbackSubmission submission) {
    return repository.submitFeedback(submission);
  }
}
