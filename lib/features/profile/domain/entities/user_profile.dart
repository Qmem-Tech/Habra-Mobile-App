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

  const UserProfile({
    required this.userId,
    required this.email,
    required this.fullName,
    this.phone,
    this.bio,
    this.location,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [userId, email, fullName, phone, bio, location, avatarUrl];
}
