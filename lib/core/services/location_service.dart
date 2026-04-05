import 'package:dartz/dartz.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/business_address_data.dart';
import '../error/failures.dart';
import '../../features/home/domain/entities/location_entity.dart';

/// Service for device location and geocoding.
class LocationService {
  LocationService();

  /// Check if location services are enabled.
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  /// Request location permission. Returns true if granted.
  Future<bool> requestPermission() async {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.deniedForever) {
      return false;
    }
    if (status == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      return requested == LocationPermission.whileInUse ||
          requested == LocationPermission.always;
    }
    return true;
  }

  /// Get current position and reverse geocode to [BusinessAddressData].
  /// Returns [Left(Failure)] if permission denied, service disabled, or geocoding fails.
  Future<Either<Failure, BusinessAddressData>> getCurrentLocationAsAddress() async {
    final posResult = await getCurrentPosition();
    return posResult.fold(
      (f) => Left(f),
      (position) => reverseGeocodeToAddress(position.latitude, position.longitude),
    );
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
