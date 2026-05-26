import 'package:supabase_flutter/supabase_flutter.dart';

import '../location/user_geo_for_feed.dart';

/// Calls `habra_feed_nearby_business_ids` / `habra_feed_nearby_event_ids`.
/// Returns `null` if the RPC is missing or errors (caller should skip geo filter).
class NearbyFeedRpcHelper {
  NearbyFeedRpcHelper(this._client);

  final SupabaseClient _client;

  Future<List<String>?> nearbyBusinessIds(UserGeoForFeed geo) async {
    try {
      final dynamic res = await _client.rpc(
        'habra_feed_nearby_business_ids',
        params: <String, dynamic>{
          'p_lat': geo.latitude,
          'p_lng': geo.longitude,
          'p_radius_km': geo.radiusKm,
          'p_limit': 400,
        },
      );
      if (res == null) return <String>[];
      final list = res as List<dynamic>;
      return list
          .map((e) {
            if (e is Map) return e['business_id']?.toString();
            return null;
          })
          .whereType<String>()
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<String>?> nearbyEventIds(UserGeoForFeed geo) async {
    try {
      final dynamic res = await _client.rpc(
        'habra_feed_nearby_event_ids',
        params: <String, dynamic>{
          'p_lat': geo.latitude,
          'p_lng': geo.longitude,
          'p_radius_km': geo.radiusKm,
          'p_limit': 200,
        },
      );
      if (res == null) return <String>[];
      final list = res as List<dynamic>;
      return list
          .map((e) {
            if (e is Map) return e['event_id']?.toString();
            return null;
          })
          .whereType<String>()
          .toList();
    } catch (_) {
      return null;
    }
  }
}
