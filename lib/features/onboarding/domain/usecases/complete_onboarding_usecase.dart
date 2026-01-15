import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/onboarding_repository.dart';

/// Use case to mark onboarding as completed
class CompleteOnboardingUseCase {
  final OnboardingRepository repository;

  CompleteOnboardingUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    try {
      await repository.completeOnboarding();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
