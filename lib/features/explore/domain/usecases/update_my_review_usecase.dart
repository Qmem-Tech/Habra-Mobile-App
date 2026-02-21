import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/my_review.dart';
import '../repositories/businesses_repository.dart';

class UpdateMyReviewUseCase {
  final BusinessesRepository repository;

  UpdateMyReviewUseCase(this.repository);

  Future<Either<Failure, MyReview>> call(
    String reviewId, {
    int? rating,
    String? comment,
  }) {
    return repository.updateReview(reviewId, rating: rating, comment: comment);
  }
}
