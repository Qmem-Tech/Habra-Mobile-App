import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: _roleFromString(json['role'] as String? ?? 'customer'),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': roleToString(role),
      'avatarUrl': avatarUrl,
    };
  }

  /// From Supabase profiles row (id, email, full_name, role).
  factory UserModel.fromSupabaseProfile(Map<String, dynamic> profile) {
    final id = profile['id'] as String? ?? '';
    final email = profile['email'] as String? ?? '';
    final name = profile['full_name'] as String? ?? '';
    final roleString = profile['role'] as String? ?? 'customer';
    final avatarUrl = profile['avatar_url'] as String?;
    return UserModel(
      id: id,
      email: email,
      name: name,
      role: _roleFromString(roleString),
      avatarUrl: avatarUrl,
    );
  }

  static UserRole _roleFromString(String value) {
    switch (value) {
      case 'businessOwner':
        return UserRole.businessOwner;
      case 'admin':
        return UserRole.admin;
      case 'guest':
        return UserRole.guest;
      case 'customer':
        return UserRole.customer;
      default:
        return UserRole.customer;
    }
  }

  static String roleToString(UserRole role) {
    switch (role) {
      case UserRole.businessOwner:
        return 'businessOwner';
      case UserRole.admin:
        return 'admin';
      case UserRole.guest:
        return 'guest';
      case UserRole.customer:
        return 'customer';
    }
  }
}
