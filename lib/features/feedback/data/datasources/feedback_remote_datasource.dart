import '../models/feedback_submission_model.dart';

abstract class FeedbackRemoteDataSource {
  Future<void> submitFeedback(FeedbackSubmissionModel submission);
}
