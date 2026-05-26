import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/feedback_ticket.dart';
import '../repositories/feedback_repository.dart';

class ListFeedbackForAdminUseCase {
  final FeedbackRepository repository;

  ListFeedbackForAdminUseCase(this.repository);

  Future<Either<Failure, List<FeedbackTicket>>> call() {
    return repository.listFeedbackForAdmin();
  }
}
