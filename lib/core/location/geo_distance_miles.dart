import 'dart:math' as math;

import 'user_geo_for_feed.dart';

/// Great-circle distance in miles, or null if coordinates are missing.
double? distanceMilesFromGeo(UserGeoForFeed? geo, double? targetLat, double? targetLng) {
  if (geo == null || targetLat == null || targetLng == null) return null;
  return haversineMiles(geo.latitude, geo.longitude, targetLat, targetLng);
}

/// Earth great-circle distance in miles (WGS84 sphere approximation).
double haversineMiles(double lat1, double lon1, double lat2, double lon2) {
  const rMi = 3958.8;
  final p = math.pi / 180.0;
  final a = 0.5 -
      math.cos((lat2 - lat1) * p) / 2 +
      math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
  return rMi * 2 * math.asin(math.sqrt(math.min(1, math.max(0, a))));
}
