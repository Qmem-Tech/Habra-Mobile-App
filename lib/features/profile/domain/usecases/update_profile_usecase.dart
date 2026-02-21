import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Either<Failure, UserProfile>> call(
      String userId, UserProfileUpdate update) {
    return repository.updateProfile(userId, update);
  }
}
