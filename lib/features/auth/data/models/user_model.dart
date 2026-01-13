import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: _roleFromString(json['role'] as String? ?? 'customer'),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': roleToString(role),
    };
  }

  /// Helper to create a [UserModel] from Firebase Auth + Firestore data.
  factory UserModel.fromFirebase({
    required String uid,
    required String email,
    required String name,
    required String roleString,
  }) {
    final role = _roleFromString(roleString);
    return UserModel(
      id: uid,
      email: email,
      name: name,
      role: role,
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
      default:
        return 'customer';
    }
  }
}
