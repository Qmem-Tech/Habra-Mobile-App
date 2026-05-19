import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_tables.dart';
import 'supabase_mappers.dart';

class LocationWriteHelper {
  LocationWriteHelper(this._client);

  final SupabaseClient _client;

  Future<String?> createOrReuseFromPayload(
    Map<String, dynamic> payload, {
    required String? name,
    required String? addressLine1,
    String? addressLine2,
    required String? city,
    required String? state,
    String? country,
    String? postalCode,
    required double? latitude,
    required double? longitude,
    String? placeId,
    String? googleMapsUrl,
    bool? isVerified,
  }) async {
    final cleanPlaceId = _clean(placeId);
    if (cleanPlaceId != null) {
      try {
        final existing = await _client
            .from(SupabaseTables.locations)
            .select('id')
            .eq('place_id', cleanPlaceId)
            .maybeSingle();
        if (existing != null) {
          final row = Map<String, dynamic>.from(existing);
          final id = parseString(row['id']);
          if (id != null) return id;
        }
      } on PostgrestException catch (e) {
        if (_isMissingLocationsSchema(e)) return null;
        rethrow;
      }
    }

    final locationPayload = <String, dynamic>{
      'name': _clean(name),
      'address_line1': _clean(addressLine1),
      'address_line2': _clean(addressLine2),
      'city': _clean(city),
      'state': _clean(state),
      'country': _clean(country) ?? 'US',
      'postal_code': _clean(postalCode),
      'latitude': latitude,
      'longitude': longitude,
      'place_id': cleanPlaceId,
      'google_maps_url': _clean(googleMapsUrl),
      if (isVerified != null) 'is_verified': isVerified,
    }..removeWhere((_, value) => value == null || value == '');

    if (locationPayload.length <= 1 &&
        latitude == null &&
        longitude == null &&
        cleanPlaceId == null) {
      return null;
    }

    try {
      final inserted = await _client
          .from(SupabaseTables.locations)
          .insert(locationPayload)
          .select('id')
          .single();
      return parseString(Map<String, dynamic>.from(inserted)['id']);
    } on PostgrestException catch (e) {
      if (_isMissingLocationsSchema(e)) return null;
      rethrow;
    }
  }

  Future<void> attachBusinessLocation(Map<String, dynamic> payload) async {
    final id = await createOrReuseFromPayload(
      payload,
      name:
          parseString(payload['location_name']) ?? parseString(payload['name']),
      addressLine1: parseString(payload['address_street']),
      city: parseString(payload['address_city']),
      state: parseString(payload['address_state']),
      country: parseString(payload['address_country']),
      postalCode: parseString(payload['address_zip']),
      latitude: parseDouble(payload['latitude']),
      longitude: parseDouble(payload['longitude']),
      placeId: parseString(payload['place_id']),
      googleMapsUrl: parseString(payload['google_maps_url']),
      isVerified: parseBool(payload['is_verified']),
    );
    if (id != null) payload['location_id'] = id;
    _removeLocationOnlyKeys(payload);
  }

  Future<void> attachEventLocation(Map<String, dynamic> payload) async {
    if (parseBool(payload['is_online'])) {
      payload['location_id'] = null;
      _removeLocationOnlyKeys(payload);
      return;
    }

    final id = await createOrReuseFromPayload(
      payload,
      name:
          parseString(payload['location_name']) ??
          parseString(payload['venue_name']),
      addressLine1: parseString(payload['venue_address']),
      city: parseString(payload['location_city']),
      state: parseString(payload['location_state']),
      country: parseString(payload['location_country']),
      postalCode: parseString(payload['location_postal_code']),
      latitude: parseDouble(payload['venue_lat']),
      longitude: parseDouble(payload['venue_lng']),
      placeId: parseString(payload['place_id']),
      googleMapsUrl: parseString(payload['google_maps_url']),
    );
    if (id != null) payload['location_id'] = id;
    _removeLocationOnlyKeys(payload);
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static void _removeLocationOnlyKeys(Map<String, dynamic> payload) {
    payload
      ..remove('location_name')
      ..remove('location_city')
      ..remove('location_state')
      ..remove('location_country')
      ..remove('location_postal_code')
      ..remove('place_id')
      ..remove('google_maps_url');
  }

  static bool _isMissingLocationsSchema(PostgrestException e) {
    final message = e.message.toLowerCase();
    return e.code == 'PGRST200' ||
        message.contains('locations') &&
            (message.contains('does not exist') ||
                message.contains('schema cache') ||
                message.contains('could not find') ||
                message.contains('relationship'));
  }
}
