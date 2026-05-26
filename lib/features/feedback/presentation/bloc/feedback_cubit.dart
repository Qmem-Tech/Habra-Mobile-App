import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/feedback_submission.dart';
import '../../domain/usecases/submit_feedback_usecase.dart';
import 'feedback_state.dart';

class FeedbackCubit extends Cubit<FeedbackState> {
  final SubmitFeedbackUseCase submitFeedbackUseCase;

  FeedbackCubit({required this.submitFeedbackUseCase})
      : super(FeedbackInitial());

  Future<void> submit({
    required FeedbackType type,
    required String text,
  }) async {
    if (text.trim().isEmpty) {
      emit(FeedbackError('Please enter your feedback'));
      return;
    }
    emit(FeedbackSubmitting());

    final result = await submitFeedbackUseCase(
      FeedbackSubmission(type: type, text: text.trim()),
    );

    result.fold(
      (failure) => emit(FeedbackError(failure.message)),
      (_) => emit(FeedbackSuccess()),
    );
  }
}
