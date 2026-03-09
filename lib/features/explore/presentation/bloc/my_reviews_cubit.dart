import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/delete_my_review_usecase.dart';
import '../../domain/usecases/get_my_reviews_usecase.dart';
import '../../domain/usecases/update_my_review_usecase.dart';
import 'my_reviews_state.dart';

class MyReviewsCubit extends Cubit<MyReviewsState> {
  final GetMyReviewsUseCase getMyReviewsUseCase;
  final UpdateMyReviewUseCase updateMyReviewUseCase;
  final DeleteMyReviewUseCase deleteMyReviewUseCase;

  MyReviewsCubit({
    required this.getMyReviewsUseCase,
    required this.updateMyReviewUseCase,
    required this.deleteMyReviewUseCase,
  }) : super(MyReviewsInitial());

  Future<void> loadMyReviews() async {
    emit(MyReviewsLoading());

    final result = await getMyReviewsUseCase();
    result.fold(
      (failure) => emit(MyReviewsError(failure.message)),
      (reviews) => emit(MyReviewsLoaded(reviews)),
    );
  }

  Future<bool> updateReview(String reviewId, {int? rating, String? comment}) async {
    final result = await updateMyReviewUseCase(reviewId, rating: rating, comment: comment);
    return result.fold(
      (_) => false,
      (updated) {
        final current = state;
        if (current is MyReviewsLoaded) {
          final list = current.reviews.map((r) => r.id == reviewId ? updated : r).toList();
          emit(MyReviewsLoaded(list));
        }
        return true;
      },
    );
  }

  Future<bool> deleteReview(String reviewId) async {
    final result = await deleteMyReviewUseCase(reviewId);
    return result.fold(
      (_) => false,
      (_) {
        final current = state;
        if (current is MyReviewsLoaded) {
          final list = current.reviews.where((r) => r.id != reviewId).toList();
          emit(MyReviewsLoaded(list));
        }
        return true;
      },
    );
  }
}
