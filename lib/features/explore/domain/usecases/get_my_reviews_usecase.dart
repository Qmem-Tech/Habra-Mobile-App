import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/my_review.dart';
import '../repositories/businesses_repository.dart';

class GetMyReviewsUseCase {
  final BusinessesRepository repository;

  GetMyReviewsUseCase(this.repository);

  Future<Either<Failure, List<MyReview>>> call() {
    return repository.getMyReviews();
  }
}
