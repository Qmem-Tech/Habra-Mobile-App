import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/complete_onboarding_usecase.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final CompleteOnboardingUseCase completeOnboardingUseCase;

  OnboardingCubit({
    required this.completeOnboardingUseCase,
  }) : super(OnboardingInitial());

  Future<void> completeOnboarding() async {
    emit(OnboardingLoading());

    final result = await completeOnboardingUseCase();

    result.fold(
      (failure) => emit(OnboardingError(failure.message)),
      (_) => emit(OnboardingCompleted()),
    );
  }
}
