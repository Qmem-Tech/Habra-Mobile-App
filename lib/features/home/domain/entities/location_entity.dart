import 'package:equatable/equatable.dart';

class LocationEntity extends Equatable {
  final String id;
  final String city;
  final String? state;
  final String country;
  final String? displayName; // Full display name
  final double? latitude;
  final double? longitude;

  const LocationEntity({
    required this.id,
    required this.city,
    this.state,
    required this.country,
    this.displayName,
    this.latitude,
    this.longitude,
  });

  String get fullDisplayName {
    if (displayName != null) return displayName!;
    if (state != null) {
      return '$city, $state, $country';
    }
    return '$city, $country';
  }

  @override
  List<Object?> get props => [
        id,
        city,
        state,
        country,
        displayName,
        latitude,
        longitude,
      ];
}
