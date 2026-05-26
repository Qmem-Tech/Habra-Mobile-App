import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/event_detail.dart';
import '../utils/event_geocode_query.dart';

/// Full-screen map for event location with directions option.
///
/// Pass [resolvedLatitude] / [resolvedLongitude] when the preview already geocoded
/// the address; otherwise this page will try to geocode from [EventDetail].
class EventMapPage extends StatefulWidget {
  const EventMapPage({
    super.key,
    required this.event,
    this.resolvedLatitude,
    this.resolvedLongitude,
  });

  final EventDetail event;
  final double? resolvedLatitude;
  final double? resolvedLongitude;

  @override
  State<EventMapPage> createState() => _EventMapPageState();
}

class _EventMapPageState extends State<EventMapPage> {
  GoogleMapController? _mapController;
  bool _isLoadingUserLocation = false;

  double? _lat;
  double? _lng;
  bool _resolving = true;
  String? _resolveNote;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    final fromPreview = widget.resolvedLatitude != null &&
        widget.resolvedLongitude != null;
    final fromDb =
        e.latitude != null && e.longitude != null && !e.isOnline;

    if (fromPreview) {
      _lat = widget.resolvedLatitude;
      _lng = widget.resolvedLongitude;
      _resolving = false;
    } else if (fromDb) {
      _lat = e.latitude;
      _lng = e.longitude;
      _resolving = false;
    } else if (!e.isOnline) {
      final q = geocodeQueryForEvent(e);
      if (q != null && q.trim().isNotEmpty) {
        _geocode(q.trim());
      } else {
        _resolving = false;
      }
    } else {
      _resolving = false;
    }
  }

  Future<void> _geocode(String query) async {
    final result = await di.sl<LocationService>().geocodeAddress(query);
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _resolving = false;
          _resolveNote = failure.message;
        });
      },
      (coords) {
        setState(() {
          _resolving = false;
          _lat = coords.lat;
          _lng = coords.lng;
        });
      },
    );
  }

  LatLng get _eventPosition => LatLng(_lat!, _lng!);

  Future<void> _onMyLocationPressed() async {
    final granted = await di.sl<PermissionService>().requestWithDialog(
      context,
      AppPermission.location,
    );
    if (!granted || !mounted) return;
    setState(() => _isLoadingUserLocation = true);
    final result = await di.sl<LocationService>().getCurrentPosition();
    setState(() => _isLoadingUserLocation = false);
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        }
      },
      (position) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      },
    );
  }

  Future<void> _openInExternalMaps() async {
    await launchEventInExternalMaps(
      context,
      widget.event,
      latitude: _lat,
      longitude: _lng,
    );
  }

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_resolving) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Location')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(height: 16),
              Text('Loading map…'),
            ],
          ),
        ),
      );
    }

    if (_lat == null || _lng == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Location')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.location_off, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                widget.event.venue,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.event.fullAddress,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (_resolveNote != null) ...[
                const SizedBox(height: 12),
                Text(
                  _resolveNote!,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
              const Spacer(),
              AppButton(
                text: 'Open in Maps',
                onPressed: () => _openInExternalMaps(),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openInExternalMaps,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _eventPosition,
              zoom: 15,
            ),
            mapType: MapType.normal,
            compassEnabled: true,
            buildingsEnabled: true,
            markers: {
              Marker(
                markerId: MarkerId(widget.event.id),
                position: _eventPosition,
                infoWindow: InfoWindow(
                  title: widget.event.venue,
                  snippet: widget.event.fullAddress,
                ),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'event_my_location',
              onPressed: _isLoadingUserLocation ? null : _onMyLocationPressed,
              backgroundColor: AppColors.brandPrimary,
              child: _isLoadingUserLocation
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.venue,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.event.fullAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        text: 'Get Directions',
                        width: 160,
                        height: 40,
                        onPressed: _openInExternalMaps,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
