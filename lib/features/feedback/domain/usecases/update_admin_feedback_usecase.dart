import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/feedback_ticket.dart';
import '../repositories/feedback_repository.dart';

class UpdateAdminFeedbackUseCase {
  final FeedbackRepository repository;

  UpdateAdminFeedbackUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String id,
    required FeedbackTicketStatus status,
    String? adminNotes,
  }) {
    return repository.updateFeedbackAdmin(
      id: id,
      status: status,
      adminNotes: adminNotes,
    );
  }
}
