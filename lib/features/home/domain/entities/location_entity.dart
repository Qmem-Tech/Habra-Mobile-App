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

/// Parses `profiles.city` (free text like "Seattle" or "Seattle, WA") for session / feed use.
LocationEntity locationEntityFromProfileCity(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const LocationEntity(id: 'profile', city: '', country: 'USA');
  }
  final parts = trimmed
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.length == 1) {
    return LocationEntity(
      id: 'profile',
      city: parts.first,
      country: 'USA',
      displayName: trimmed,
    );
  }
  return LocationEntity(
    id: 'profile',
    city: parts.first,
    state: parts[1],
    country: parts.length > 2 ? parts[2] : 'USA',
    displayName: trimmed,
  );
}
