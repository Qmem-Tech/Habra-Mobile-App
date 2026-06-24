import '../supabase/supabase_mappers.dart';
import '../location/geo_coordinates.dart';

class NormalizedLocation {
  const NormalizedLocation({
    this.id,
    this.name,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.placeId,
    this.timezone,
    this.isVerified = false,
    this.googleMapsUrl,
  });

  final String? id;
  final String? name;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final String? timezone;
  final bool isVerified;
  final String? googleMapsUrl;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get displayAddress {
    final parts = <String>[
      if (addressLine1 != null && addressLine1!.isNotEmpty) addressLine1!,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2!,
      if (city != null && city!.isNotEmpty) city!,
      if (state != null && state!.isNotEmpty) state!,
      if (postalCode != null && postalCode!.isNotEmpty) postalCode!,
    ];
    return parts.join(', ');
  }

  factory NormalizedLocation.fromRow(Map<String, dynamic> row) {
    final fromGeo = parsePostGisPoint(row['location']);
    var latitude = fromGeo?.lat ?? parseDouble(row['latitude']);
    var longitude = fromGeo?.lng ?? parseDouble(row['longitude']);
    final normalized = normalizeLatLng(latitude, longitude);
    latitude = normalized?.lat;
    longitude = normalized?.lng;
    return NormalizedLocation(
      id: parseString(row['id']),
      name: parseString(row['name']),
      addressLine1: parseString(row['address_line1']),
      addressLine2: parseString(row['address_line2']),
      city: parseString(row['city']),
      state: parseString(row['state']),
      country: parseString(row['country']),
      postalCode: parseString(row['postal_code']),
      latitude: latitude,
      longitude: longitude,
      placeId: parseString(row['place_id']),
      timezone: parseString(row['timezone']),
      isVerified: parseBool(row['is_verified']),
      googleMapsUrl: parseString(row['google_maps_url']),
    );
  }

  static NormalizedLocation? maybeFromEmbedded(dynamic raw) {
    if (raw is Map) {
      return NormalizedLocation.fromRow(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
