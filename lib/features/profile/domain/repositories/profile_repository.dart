import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getProfile(String userId);
  Future<Either<Failure, UserProfile>> updateProfile(String userId, UserProfileUpdate update);
}

/// Partial update payload for profile.
class UserProfileUpdate {
  final String? fullName;
  final String? phone;
  final String? bio;
  final String? location;
  final String? avatarUrl;

  const UserProfileUpdate({
    this.fullName,
    this.phone,
    this.bio,
    this.location,
    this.avatarUrl,
  });
}
