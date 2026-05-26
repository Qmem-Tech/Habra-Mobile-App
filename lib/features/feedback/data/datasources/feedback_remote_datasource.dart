import '../../domain/entities/feedback_ticket.dart';
import '../models/feedback_submission_model.dart';

abstract class FeedbackRemoteDataSource {
  Future<void> submitFeedback(FeedbackSubmissionModel submission);

  Future<List<FeedbackTicket>> listFeedbackForAdmin();

  Future<void> updateFeedbackAdmin({
    required String id,
    required FeedbackTicketStatus status,
    String? adminNotes,
  });
}
