import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';
import '../domain/business_address_data.dart';
import '../error/failures.dart';
import '../../features/home/domain/entities/location_entity.dart';

/// Service for device location and geocoding.
class LocationService {
  LocationService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Check if location services are enabled.
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  /// Request location permission. Returns true if granted.
  Future<bool> requestPermission() async {
    var status = await Geolocator.checkPermission();
    if (status == LocationPermission.deniedForever) {
      return false;
    }
    if (status == LocationPermission.denied ||
        status == LocationPermission.unableToDetermine) {
      var requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.whileInUse ||
          requested == LocationPermission.always) {
        return true;
      }
      // iOS: after the system sheet dismisses, Geolocator can briefly still report
      // denied while permission_handler already granted — poll until settled.
      for (var i = 0; i < 12; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        status = await Geolocator.checkPermission();
        if (status == LocationPermission.whileInUse ||
            status == LocationPermission.always) {
          return true;
        }
        if (status == LocationPermission.deniedForever) {
          return false;
        }
      }
      return false;
    }
    return true;
  }

  /// Get current position and reverse geocode to [BusinessAddressData].
  /// Returns [Left(Failure)] if permission denied, service disabled, or geocoding fails.
  ///
  /// When [nativePermissionAlreadyGranted] is true, skips [requestPermission] and calls
  /// [Geolocator.getCurrentPosition] directly (use after [PermissionService.requestWithDialog]
  /// so iOS does not get stuck on a stale Geolocator permission read).
  Future<Either<Failure, BusinessAddressData>> getCurrentLocationAsAddress({
    bool nativePermissionAlreadyGranted = false,
  }) async {
    final Either<Failure, Position> posResult;
    if (nativePermissionAlreadyGranted) {
      posResult = await _getPositionAfterExternalPermissionGrant();
    } else {
      posResult = await getCurrentPosition();
    }
    return posResult.fold(
      (f) => Left(f),
      (position) => reverseGeocodeToAddress(position.latitude, position.longitude),
    );
  }

  /// Used when [permission_handler] / the user already granted location in the OS sheet.
  Future<Either<Failure, Position>> _getPositionAfterExternalPermissionGrant() async {
    final enabled = await isLocationServiceEnabled();
    if (!enabled) {
      return const Left(LocationFailure('Location services are disabled.'));
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      return Right(position);
    } on PermissionDeniedException {
      return getCurrentPosition();
    } on LocationServiceDisabledException {
      return const Left(LocationFailure('Location services are disabled.'));
    } catch (e) {
      return Left(LocationFailure('Could not get position: $e'));
    }
  }

  /// Get current position and reverse geocode to a [LocationEntity].
  /// Returns [Left(Failure)] if permission denied, service disabled, or geocoding fails.
  Future<Either<Failure, LocationEntity>> getCurrentLocation() async {
    final enabled = await isLocationServiceEnabled();
    if (!enabled) {
      return const Left(
        LocationFailure('Location services are disabled.'),
      );
    }

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      return const Left(
        LocationFailure(
          'Location permission denied. Enable in Settings to use current location.',
        ),
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return Right(
          LocationEntity(
            id: 'current',
            city: 'Unknown',
            country: 'Unknown',
            latitude: position.latitude,
            longitude: position.longitude,
            displayName: 'Current Location',
          ),
        );
      }

      final p = placemarks.first;
      final city = p.locality ?? p.subAdministrativeArea ?? 'Unknown';
      final state = p.administrativeArea;
      final country = p.country ?? 'Unknown';
      final displayName = [
        if (p.thoroughfare != null) p.thoroughfare,
        city,
        if (state != null) state,
        country,
      ].whereType<String>().join(', ');

      return Right(
        LocationEntity(
          id: 'current_${position.latitude}_${position.longitude}',
          city: city,
          state: state,
          country: country,
          displayName: displayName,
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } on LocationServiceDisabledException {
      return const Left(LocationFailure('Location services are disabled.'));
    } on PermissionDeniedException {
      return const Left(LocationFailure('Location permission denied.'));
    } catch (e) {
      return Left(LocationFailure('Could not get location: $e'));
    }
  }

  /// Geocode an address string to lat/lng.
  /// Returns [Left(Failure)] if address not found or geocoding fails.
  Future<Either<Failure, ({double lat, double lng})>> geocodeAddress(String address) async {
    if (address.trim().isEmpty) {
      return const Left(LocationFailure('Address is empty.'));
    }
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        return const Left(LocationFailure('Could not find location for this address.'));
      }
      final loc = locations.first;
      return Right((lat: loc.latitude, lng: loc.longitude));
    } catch (e) {
      return Left(LocationFailure('Could not geocode address: $e'));
    }
  }

  /// Reverse geocode coordinates to [BusinessAddressData].
  Future<Either<Failure, BusinessAddressData>> reverseGeocodeToAddress(
    double lat,
    double lng,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return Right(
          BusinessAddressData(latitude: lat, longitude: lng),
        );
      }
      final p = placemarks.first;
      final street = [
        if (p.subThoroughfare != null) p.subThoroughfare,
        if (p.thoroughfare != null) p.thoroughfare,
      ].whereType<String>().join(' ');
      return Right(
        BusinessAddressData(
          street: street.isNotEmpty ? street : null,
          city: p.locality ?? p.subAdministrativeArea,
          state: p.administrativeArea,
          zipCode: p.postalCode,
          latitude: lat,
          longitude: lng,
        ),
      );
    } catch (e) {
      return Left(LocationFailure('Could not get address: $e'));
    }
  }

  /// Parse Google Maps URL to extract lat/lng.
  /// Supports: .../place/.../@lat,lng, ...?q=lat,lng, .../search/?query=lat,lng
  Either<Failure, ({double lat, double lng})> parseGoogleMapsLink(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return const Left(LocationFailure('Empty link.'));
    }

    // Pattern: @lat,lng or @lat,lng,zoom
    final atMatch = RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)').firstMatch(trimmed);
    if (atMatch != null) {
      final lat = double.tryParse(atMatch.group(1)!);
      final lng = double.tryParse(atMatch.group(2)!);
      if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
        return Right((lat: lat, lng: lng));
      }
    }

    // Pattern: q=lat,lng or query=lat,lng
    final qMatch = RegExp(r'[?&](?:q|query)=(-?\d+\.?\d*),(-?\d+\.?\d*)').firstMatch(trimmed);
    if (qMatch != null) {
      final lat = double.tryParse(qMatch.group(1)!);
      final lng = double.tryParse(qMatch.group(2)!);
      if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
        return Right((lat: lat, lng: lng));
      }
    }

    // Pattern: !3dlat!4dlng
    final dMatch = RegExp(r'!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)').firstMatch(trimmed);
    if (dMatch != null) {
      final lat = double.tryParse(dMatch.group(1)!);
      final lng = double.tryParse(dMatch.group(2)!);
      if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
        return Right((lat: lat, lng: lng));
      }
    }

    return const Left(LocationFailure(
      'Could not find coordinates in link. Paste a Google Maps link with a location.',
    ));
  }

  /// Forward-geocode a query and return up to [maxResults] structured addresses
  /// (via reverse geocode per hit). Used for address search / autocomplete UX.
  ///
  /// Note: Quality depends on the platform geocoder; for denser suggestions
  /// consider Google Places Autocomplete with an API key.
  Future<Either<Failure, List<BusinessAddressData>>> lookupAddressSuggestions(
    String query, {
    int maxResults = 5,
  }) async {
    final q = query.trim();
    if (q.length < 4) {
      return const Right([]);
    }
    if (AppConfig.isGoogleMapsConfigured) {
      final places = await _lookupGooglePlaces(q, maxResults: maxResults);
      final hasPlaces = places.fold((_) => false, (list) => list.isNotEmpty);
      if (hasPlaces) return places;
    }
    try {
      final locations = await locationFromAddress(q);
      if (locations.isEmpty) {
        return const Right([]);
      }
      final out = <BusinessAddressData>[];
      final seen = <String>{};
      for (final loc in locations.take(maxResults)) {
        final rev = await reverseGeocodeToAddress(loc.latitude, loc.longitude);
        rev.fold((_) {}, (BusinessAddressData data) {
          final key = [
            data.street ?? '',
            data.city ?? '',
            data.state ?? '',
            data.zipCode ?? '',
          ].join('|');
          if (key.replaceAll('|', '').isEmpty) return;
          if (seen.add(key)) {
            out.add(data);
          }
        });
      }
      return Right(out);
    } catch (e) {
      return Left(LocationFailure('Address lookup failed: $e'));
    }
  }

  /// Geocode address string and return full [BusinessAddressData].
  Future<Either<Failure, BusinessAddressData>> geocodeToAddress(String address) async {
    if (address.trim().isEmpty) {
      return const Left(LocationFailure('Address is empty.'));
    }
    final coordsResult = await geocodeAddress(address);
    return coordsResult.fold(
      (f) => Left(f),
      (coords) async {
        final revResult = await reverseGeocodeToAddress(coords.lat, coords.lng);
        return revResult;
      },
    );
  }

  Future<Either<Failure, List<BusinessAddressData>>> _lookupGooglePlaces(
    String query, {
    required int maxResults,
  }) async {
    try {
      final autocomplete = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'types': 'address',
          'components': 'country:us',
          'key': AppConfig.effectiveGoogleMapsApiKey,
        },
      );
      final data = autocomplete.data ?? const <String, dynamic>{};
      final status = data['status']?.toString();
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        return const Right([]);
      }
      final predictions = data['predictions'];
      if (predictions is! List || predictions.isEmpty) return const Right([]);

      final out = <BusinessAddressData>[];
      for (final prediction in predictions.take(maxResults)) {
        if (prediction is! Map) continue;
        final placeId = prediction['place_id']?.toString();
        if (placeId == null || placeId.isEmpty) continue;
        final details = await _googlePlaceDetails(placeId);
        details.fold((_) {}, out.add);
      }
      return Right(out);
    } catch (_) {
      return const Right([]);
    }
  }

  Future<Either<Failure, BusinessAddressData>> _googlePlaceDetails(String placeId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields':
              'name,formatted_address,address_component,geometry,place_id,url',
          'key': AppConfig.effectiveGoogleMapsApiKey,
        },
      );
      final data = response.data ?? const <String, dynamic>{};
      if (data['status']?.toString() != 'OK') {
        return const Left(LocationFailure('Place details unavailable.'));
      }
      final result = data['result'];
      if (result is! Map) {
        return const Left(LocationFailure('Place details unavailable.'));
      }

      final components = <String, String>{};
      final rawComponents = result['address_components'];
      if (rawComponents is List) {
        for (final item in rawComponents) {
          if (item is! Map) continue;
          final types = item['types'];
          if (types is! List) continue;
          for (final type in types) {
            final key = type.toString();
            components[key] = item['short_name']?.toString() ??
                item['long_name']?.toString() ??
                '';
          }
        }
      }

      final geometry = result['geometry'];
      final geoLocation = geometry is Map ? geometry['location'] : null;
      final lat = geoLocation is Map ? _toDouble(geoLocation['lat']) : null;
      final lng = geoLocation is Map ? _toDouble(geoLocation['lng']) : null;
      final streetNumber = components['street_number'];
      final route = components['route'];
      final street = [
        if (streetNumber != null && streetNumber.isNotEmpty) streetNumber,
        if (route != null && route.isNotEmpty) route,
      ].join(' ');

      return Right(
        BusinessAddressData(
          name: result['name']?.toString(),
          street: street.isEmpty ? null : street,
          city: components['locality'] ??
              components['postal_town'] ??
              components['administrative_area_level_2'],
          state: components['administrative_area_level_1'],
          country: components['country'],
          zipCode: components['postal_code'],
          latitude: lat,
          longitude: lng,
          placeId: result['place_id']?.toString() ?? placeId,
          formattedAddress: result['formatted_address']?.toString(),
          googleMapsUrl: result['url']?.toString(),
        ),
      );
    } catch (e) {
      return Left(LocationFailure('Place details unavailable: $e'));
    }
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Get [Position] only (for map centering).
  Future<Either<Failure, Position>> getCurrentPosition() async {
    final enabled = await isLocationServiceEnabled();
    if (!enabled) {
      return const Left(LocationFailure('Location services are disabled.'));
    }
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      return const Left(LocationFailure('Location permission denied.'));
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      return Right(position);
    } catch (e) {
      return Left(LocationFailure('Could not get position: $e'));
    }
  }
}
