import 'package:equatable/equatable.dart';
import '../../domain/entities/review.dart';

abstract class ReviewsState extends Equatable {
  const ReviewsState();

  @override
  List<Object?> get props => [];
}

class ReviewsInitial extends ReviewsState {}

class ReviewsLoading extends ReviewsState {}

class ReviewsLoaded extends ReviewsState {
  final List<Review> reviews;

  const ReviewsLoaded(this.reviews);

  @override
  List<Object?> get props => [reviews];
}

class ReviewsError extends ReviewsState {
  final String message;

  const ReviewsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Write Review States
class WriteReviewInitial extends ReviewsState {}

class WriteReviewLoading extends ReviewsState {}

class WriteReviewSuccess extends ReviewsState {
  final Review review;

  const WriteReviewSuccess(this.review);

  @override
  List<Object?> get props => [review];
}

class WriteReviewError extends ReviewsState {
  final String message;

  const WriteReviewError(this.message);

  @override
  List<Object?> get props => [message];
}
