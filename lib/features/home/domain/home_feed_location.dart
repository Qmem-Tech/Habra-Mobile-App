import '../../../../core/location/user_geo_for_feed.dart';

/// Label for legacy string-based filters plus optional coordinates for nearby RPCs.
class HomeFeedLocation {
  const HomeFeedLocation({
    required this.label,
    this.geo,
  });

  final String label;
  final UserGeoForFeed? geo;
}
