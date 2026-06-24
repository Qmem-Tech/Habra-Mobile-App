import '../domain/normalized_location.dart';
import '../supabase/supabase_mappers.dart';

/// Normalizes latitude/longitude, correcting common swapped storage mistakes.
({double lat, double lng})? normalizeLatLng(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) return null;
  var lat = latitude;
  var lng = longitude;

  final latInvalid = lat.abs() > 90;
  final lngInvalid = lng.abs() > 180;
  if (latInvalid || lngInvalid) {
    final swappedLat = longitude;
    final swappedLng = latitude;
    if (swappedLat.abs() <= 90 && swappedLng.abs() <= 180) {
      lat = swappedLat;
      lng = swappedLng;
    } else {
      return null;
    }
  }

  return (lat: lat, lng: lng);
}

/// Best-effort listing coordinates: embedded `locations` row (PostGIS first), then legacy business columns.
({double lat, double lng})? resolveListingCoordinates({
  NormalizedLocation? location,
  Map<String, dynamic>? businessRow,
}) {
  double? lat;
  double? lng;

  if (location != null) {
    lat = location.latitude;
    lng = location.longitude;
  }

  final row = businessRow;
  if (row != null) {
    lat ??= parseDouble(row['latitude']);
    lng ??= parseDouble(row['longitude']);
  }

  return normalizeLatLng(lat, lng);
}
