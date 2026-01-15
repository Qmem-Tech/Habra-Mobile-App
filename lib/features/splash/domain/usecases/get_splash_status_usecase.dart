import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/splash_status.dart';
import '../repositories/splash_repository.dart';

/// Use case to get splash screen status
class GetSplashStatusUseCase {
  final SplashRepository repository;

  GetSplashStatusUseCase(this.repository);

  Future<Either<Failure, SplashStatus>> call() async {
    try {
      final status = await repository.getSplashStatus();
      return Right(status);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
