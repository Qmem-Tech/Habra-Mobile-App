import 'package:dartz/dartz.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

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
