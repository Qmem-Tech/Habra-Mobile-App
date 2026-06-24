import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/home/domain/entities/location_entity.dart';
import '../services/location_service.dart';
import 'user_geo_for_feed.dart';

/// Ephemeral device location for the current app session only (not persisted).
/// Used as the primary "nearby" anchor per product choice: device GPS, session scope.
abstract class SessionDeviceLocationState extends Equatable {
  const SessionDeviceLocationState();

  @override
  List<Object?> get props => [];
}

class SessionDeviceLocationInitial extends SessionDeviceLocationState {
  const SessionDeviceLocationInitial();
}

class SessionDeviceLocationLoading extends SessionDeviceLocationState {
  const SessionDeviceLocationLoading();
}

class SessionDeviceLocationReady extends SessionDeviceLocationState {
  const SessionDeviceLocationReady(
    this.location, {
    this.distanceLatitude,
    this.distanceLongitude,
  });

  final LocationEntity location;

  /// Device GPS used for mile distances; may differ from [location] when the label is a saved city.
  final double? distanceLatitude;
  final double? distanceLongitude;

  @override
  List<Object?> get props => [location, distanceLatitude, distanceLongitude];
}

class SessionDeviceLocationFailure extends SessionDeviceLocationState {
  const SessionDeviceLocationFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class SessionDeviceLocationCubit extends Cubit<SessionDeviceLocationState> {
  SessionDeviceLocationCubit(this._locationService)
      : super(const SessionDeviceLocationInitial());

  final LocationService _locationService;

  void _emitReady(
    LocationEntity location, {
    double? distanceLatitude,
    double? distanceLongitude,
  }) {
    final s = state;
    final keepDistLat = distanceLatitude ??
        (s is SessionDeviceLocationReady ? s.distanceLatitude : null);
    final keepDistLng = distanceLongitude ??
        (s is SessionDeviceLocationReady ? s.distanceLongitude : null);
    emit(
      SessionDeviceLocationReady(
        location,
        distanceLatitude: keepDistLat,
        distanceLongitude: keepDistLng,
      ),
    );
  }

  /// Reads current GPS + reverse geocode. Emits [SessionDeviceLocationReady] or [SessionDeviceLocationFailure].
  Future<void> refreshFromDeviceGps() async {
    emit(const SessionDeviceLocationLoading());
    final result = await _locationService.getCurrentLocation();
    result.fold(
      (failure) => emit(SessionDeviceLocationFailure(failure.message)),
      (location) {
        emit(
          SessionDeviceLocationReady(
            location,
            distanceLatitude: location.latitude,
            distanceLongitude: location.longitude,
          ),
        );
      },
    );
  }

  /// Refreshes device GPS for distance math without changing the display label.
  Future<void> refreshDeviceGpsForDistance() async {
    final pos = await _locationService.getCurrentPosition();
    pos.fold((_) {}, (position) {
      final s = state;
      if (s is! SessionDeviceLocationReady) return;
      emit(
        SessionDeviceLocationReady(
          s.location,
          distanceLatitude: position.latitude,
          distanceLongitude: position.longitude,
        ),
      );
    });
  }

  /// Manual override (e.g. city list) — still session-only, not written to disk.
  void setSessionLocation(LocationEntity location) {
    _emitReady(location);
  }

  /// Sets session city label, then geocodes so nearby distance can be calculated.
  Future<void> setSessionLocationFromCityLabel(String cityLabel) async {
    final trimmed = cityLabel.trim();
    if (trimmed.isEmpty) return;
    var entity = locationEntityFromProfileCity(trimmed);
    _emitReady(entity);
    final geocode = await _locationService.geocodeAddress(entity.fullDisplayName);
    geocode.fold((_) {}, (coords) {
      entity = LocationEntity(
        id: entity.id,
        city: entity.city,
        state: entity.state,
        country: entity.country,
        displayName: entity.displayName,
        latitude: coords.lat,
        longitude: coords.lng,
      );
      _emitReady(entity);
    });
  }

  void clear() {
    emit(const SessionDeviceLocationInitial());
  }

  /// Display label for API calls that still expect a city string (until server-side nearby ships).
  static String fallbackLabel = 'Washington, D.C.';

  static String labelOrFallback(SessionDeviceLocationState state) {
    if (state is SessionDeviceLocationReady) {
      return state.location.fullDisplayName;
    }
    return fallbackLabel;
  }

  /// First resolved label from [context], or null if cubit missing / not ready.
  static String? tryLabel(BuildContext context) {
    final cubit = maybeOf(context);
    if (cubit == null) return null;
    final s = cubit.state;
    if (s is SessionDeviceLocationReady) {
      return s.location.fullDisplayName;
    }
    return null;
  }

  static SessionDeviceLocationCubit? maybeOf(BuildContext context) {
    try {
      return BlocProvider.of<SessionDeviceLocationCubit>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  /// Coordinates for distance / nearby RPCs when session location is ready.
  static UserGeoForFeed? tryGeo(BuildContext context) {
    final cubit = maybeOf(context);
    if (cubit == null) return null;
    final s = cubit.state;
    if (s is! SessionDeviceLocationReady) return null;

    final lat = s.distanceLatitude ?? s.location.latitude;
    final lng = s.distanceLongitude ?? s.location.longitude;
    if (lat == null || lng == null) return null;
    return UserGeoForFeed(latitude: lat, longitude: lng);
  }
}
