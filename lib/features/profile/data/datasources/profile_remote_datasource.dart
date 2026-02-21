import 'dart:io';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfile> getProfile(String userId);
  Future<UserProfile> updateProfile(String userId, UserProfileUpdate update);
  /// Uploads avatar image and returns the public URL. Path: avatars/{userId}/avatar.jpg
  Future<String> uploadAvatar(String userId, File imageFile);
}
