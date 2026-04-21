import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/feedback_submission.dart';
import '../entities/feedback_ticket.dart';

abstract class FeedbackRepository {
  Future<Either<Failure, void>> submitFeedback(FeedbackSubmission submission);

  Future<Either<Failure, List<FeedbackTicket>>> listFeedbackForAdmin();

  Future<Either<Failure, void>> updateFeedbackAdmin({
    required String id,
    required FeedbackTicketStatus status,
    String? adminNotes,
  });
}
