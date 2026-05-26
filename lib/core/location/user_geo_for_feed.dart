/// Optional user coordinates for server-side nearby filtering (see Supabase RPCs).
class UserGeoForFeed {
  const UserGeoForFeed({
    required this.latitude,
    required this.longitude,
    this.radiusKm = defaultRadiusKm,
  });

  /// Search radius for `habra_feed_nearby_*` RPCs (kilometers).
  static const double defaultRadiusKm = 80;

  final double latitude;
  final double longitude;
  final double radiusKm;
}
