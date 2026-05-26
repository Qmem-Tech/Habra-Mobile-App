import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/businesses_repository.dart';

class DeleteMyReviewUseCase {
  final BusinessesRepository repository;

  DeleteMyReviewUseCase(this.repository);

  Future<Either<Failure, void>> call(String reviewId) {
    return repository.deleteReview(reviewId);
  }
}
