import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_splash_status_usecase.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final GetSplashStatusUseCase getSplashStatusUseCase;

  SplashCubit({
    required this.getSplashStatusUseCase,
  }) : super(SplashInitial());

  Future<void> checkSplashStatus() async {
    emit(SplashLoading());

    final result = await getSplashStatusUseCase();

    result.fold(
      (failure) => emit(SplashError(failure.message)),
      (status) => emit(SplashLoaded(status)),
    );
  }
}
