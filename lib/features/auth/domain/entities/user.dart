import 'package:equatable/equatable.dart';

/// Supported user roles in the system.
///
/// - [customer]: Regular end-user using the app.
/// - [businessOwner]: Vendor / business owner using the same app with a different UI.
/// - [admin]: Super admin (internal) managing the platform.
/// - [guest]: Anonymous user with limited capabilities.
enum UserRole { customer, businessOwner, admin, guest }

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isGuest => role == UserRole.guest;
  bool get isBusinessOwner => role == UserRole.businessOwner;
  bool get isCustomer => role == UserRole.customer;
  bool get isAdmin => role == UserRole.admin;

  @override
  List<Object> get props => [id, email, name, role];
}
