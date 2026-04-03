import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/home/domain/entities/location_entity.dart';
import '../services/location_service.dart';

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
  const SessionDeviceLocationReady(this.location);

  final LocationEntity location;

  @override
  List<Object?> get props => [location];
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

  /// Reads current GPS + reverse geocode. Emits [SessionDeviceLocationReady] or [SessionDeviceLocationFailure].
  Future<void> refreshFromDeviceGps() async {
    emit(const SessionDeviceLocationLoading());
    final result = await _locationService.getCurrentLocation();
    result.fold(
      (failure) => emit(SessionDeviceLocationFailure(failure.message)),
      (location) => emit(SessionDeviceLocationReady(location)),
    );
  }

  /// Manual override (e.g. city list) — still session-only, not written to disk.
  void setSessionLocation(LocationEntity location) {
    emit(SessionDeviceLocationReady(location));
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
}
