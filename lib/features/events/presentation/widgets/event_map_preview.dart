import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/event_detail.dart';
import '../pages/event_map_page.dart';
import '../utils/event_geocode_query.dart';

/// Small map preview: uses DB coordinates when present; otherwise forward-geocodes the venue address.
class EventMapPreview extends StatefulWidget {
  const EventMapPreview({
    super.key,
    required this.event,
    this.height = 200,
    this.showDirectionsButton = true,
  });

  final EventDetail event;
  final double height;
  final bool showDirectionsButton;

  @override
  State<EventMapPreview> createState() => _EventMapPreviewState();
}

class _EventMapPreviewState extends State<EventMapPreview> {
  LatLng? _position;
  bool _loading = true;
  String? _geocodeError;

  double? get _resolvedLat => _position?.latitude;
  double? get _resolvedLng => _position?.longitude;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    if (e.latitude != null && e.longitude != null) {
      _position = LatLng(e.latitude!, e.longitude!);
      _loading = false;
    } else if (!e.isOnline) {
      final q = geocodeQueryForEvent(e);
      if (q != null && q.trim().isNotEmpty) {
        _resolveGeocode(q.trim());
      } else {
        _loading = false;
        _geocodeError = null;
      }
    } else {
      _loading = false;
    }
  }

  Future<void> _resolveGeocode(String query) async {
    final result = await di.sl<LocationService>().geocodeAddress(query);
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _loading = false;
          _geocodeError = failure.message;
        });
      },
      (coords) {
        setState(() {
          _loading = false;
          _position = LatLng(coords.lat, coords.lng);
        });
      },
    );
  }

  Future<void> _openInMaps(BuildContext context) {
    return launchEventInExternalMaps(
      context,
      widget.event,
      latitude: _resolvedLat,
      longitude: _resolvedLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;

    if (_loading) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.backgroundGrey),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading map…',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_position == null) {
      return Container(
        height: widget.height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.backgroundGrey),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              e.fullAddress.trim().isEmpty
                  ? 'Location details unavailable.'
                  : e.fullAddress,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_geocodeError != null) ...[
              const SizedBox(height: 6),
              Text(
                _geocodeError!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openInMaps(context),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open in Maps'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandPrimary,
                side: BorderSide(color: AppColors.brandPrimary),
              ),
            ),
          ],
        ),
      );
    }

    final position = _position!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => EventMapPage(
                  event: e,
                  resolvedLatitude: _resolvedLat,
                  resolvedLongitude: _resolvedLng,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: widget.height,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: position,
                      zoom: 15,
                    ),
                    mapType: MapType.normal,
                    compassEnabled: true,
                    buildingsEnabled: true,
                    markers: {
                      Marker(
                        markerId: MarkerId(e.id),
                        position: position,
                        infoWindow: InfoWindow(
                          title: e.venue,
                          snippet: e.fullAddress,
                        ),
                      ),
                    },
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    liteModeEnabled: false,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => EventMapPage(
                                event: e,
                                resolvedLatitude: _resolvedLat,
                                resolvedLongitude: _resolvedLng,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fullscreen,
                                size: 18,
                                color: AppColors.brandPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'View on map',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showDirectionsButton) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _openInMaps(context),
                icon: const Icon(Icons.directions, size: 20),
                label: const Text('Get directions'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openInMaps(context),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open in Maps'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandPrimary,
                  side: BorderSide(color: AppColors.brandPrimary),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
