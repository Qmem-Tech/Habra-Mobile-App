import 'package:equatable/equatable.dart';

/// Extended profile for display and update (name, phone, bio, location, avatar).
class UserProfile extends Equatable {
  final String userId;
  final String email;
  final String fullName;
  final String? phone;
  final String? bio;
  final String? location;
  final String? avatarUrl;
  /// Account / profile creation time from `profiles.created_at` when present.
  final DateTime? createdAt;

  const UserProfile({
    required this.userId,
    required this.email,
    required this.fullName,
    this.phone,
    this.bio,
    this.location,
    this.avatarUrl,
    this.createdAt,
  });

  @override
  List<Object?> get props =>
      [userId, email, fullName, phone, bio, location, avatarUrl, createdAt];
}
