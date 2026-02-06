import 'package:equatable/equatable.dart';

/// Business location for "Select Location" step.
class BoostLocation extends Equatable {
  const BoostLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.viewsPerMonth,
    required this.rating,
  });

  final String id;
  final String name;
  final String address;
  final String viewsPerMonth;
  final double rating;

  @override
  List<Object?> get props => [id, name, address, viewsPerMonth, rating];
}
