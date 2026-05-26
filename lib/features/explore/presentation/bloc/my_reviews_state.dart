import 'package:equatable/equatable.dart';
import '../../domain/entities/my_review.dart';

abstract class MyReviewsState extends Equatable {
  const MyReviewsState();

  @override
  List<Object?> get props => [];
}

class MyReviewsInitial extends MyReviewsState {}

class MyReviewsLoading extends MyReviewsState {}

class MyReviewsLoaded extends MyReviewsState {
  final List<MyReview> reviews;

  const MyReviewsLoaded(this.reviews);

  @override
  List<Object?> get props => [reviews];
}

class MyReviewsError extends MyReviewsState {
  final String message;

  const MyReviewsError(this.message);

  @override
  List<Object?> get props => [message];
}
