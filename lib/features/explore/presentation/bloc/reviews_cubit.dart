import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_business_reviews_usecase.dart';
import '../../domain/usecases/write_review_usecase.dart';
import 'reviews_state.dart';

class ReviewsCubit extends Cubit<ReviewsState> {
  final GetBusinessReviewsUseCase getBusinessReviewsUseCase;
  final WriteReviewUseCase writeReviewUseCase;

  ReviewsCubit({
    required this.getBusinessReviewsUseCase,
    required this.writeReviewUseCase,
  }) : super(ReviewsInitial());

  Future<void> loadReviews(String businessId) async {
    emit(ReviewsLoading());

    final result = await getBusinessReviewsUseCase(businessId);

    result.fold(
      (failure) => emit(ReviewsError(failure.message)),
      (reviews) => emit(ReviewsLoaded(reviews)),
    );
  }

  Future<void> writeReview({
    required String businessId,
    required int rating,
    required String comment,
    List<String>? photoUrls,
  }) async {
    emit(WriteReviewLoading());

    final result = await writeReviewUseCase(
      businessId: businessId,
      rating: rating,
      comment: comment,
      photoUrls: photoUrls,
    );

    result.fold(
      (failure) => emit(WriteReviewError(failure.message)),
      (review) => emit(WriteReviewSuccess(review)),
    );
  }
}
