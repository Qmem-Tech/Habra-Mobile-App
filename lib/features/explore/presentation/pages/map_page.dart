import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/permissions/app_permission.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../injection/injection_container.dart' as di;

/// True when [latitude]/[longitude] are usable for the map (not null island / unset DB rows).
bool isValidBusinessMapCoordinate(double latitude, double longitude) {
  if (latitude.isNaN || longitude.isNaN) return false;
  if (latitude < -90 || latitude > 90) return false;
  if (longitude < -180 || longitude > 180) return false;
  const t = 1e-6;
  if (latitude.abs() < t && longitude.abs() < t) return false;
  return true;
}

class MapPage extends StatefulWidget {
  final String businessId;
  final double latitude;
  final double longitude;
  final String? businessName;
  final String? businessAddress;
  final String? subtitle;

  const MapPage({
    super.key,
    required this.businessId,
    required this.latitude,
    required this.longitude,
    this.businessName,
    this.businessAddress,
    this.subtitle,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final LocationService _locationService = di.sl<LocationService>();
  bool _isLoadingUserLocation = false;
  MapType _mapType = MapType.normal;

  late double _targetLat;
  late double _targetLng;
  bool _resolvingGeocode = false;
  bool _showInlineMap = false;

  @override
  void initState() {
    super.initState();
    if (isValidBusinessMapCoordinate(widget.latitude, widget.longitude)) {
      _targetLat = widget.latitude;
      _targetLng = widget.longitude;
      _showInlineMap = true;
    } else {
      _targetLat = 0;
      _targetLng = 0;
      _resolvingGeocode = true;
      _tryGeocodeFromAddress();
    }
  }

  Future<void> _tryGeocodeFromAddress() async {
    final raw = widget.businessAddress?.trim() ?? '';
    final unusable = raw.isEmpty ||
        raw.toLowerCase() == 'address not available';
    if (unusable) {
      if (mounted) {
        setState(() {
          _resolvingGeocode = false;
          _showInlineMap = false;
        });
      }
      return;
    }

    try {
      final locations = await locationFromAddress(raw);
      if (!mounted) return;
      if (locations.isEmpty) {
        setState(() {
          _resolvingGeocode = false;
          _showInlineMap = false;
        });
        return;
      }
      final loc = locations.first;
      final lat = loc.latitude;
      final lng = loc.longitude;
      if (!isValidBusinessMapCoordinate(lat, lng)) {
        setState(() {
          _resolvingGeocode = false;
          _showInlineMap = false;
        });
        return;
      }
      setState(() {
        _targetLat = lat;
        _targetLng = lng;
        _resolvingGeocode = false;
        _showInlineMap = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvingGeocode = false;
          _showInlineMap = false;
        });
      }
    }
  }

  LatLng get _businessPosition => LatLng(_targetLat, _targetLng);

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _onMyLocationPressed() async {
    if (!_showInlineMap) return;
    final hasPermission = await di.sl<PermissionService>().isGranted(
      AppPermission.location,
    );
    if (!hasPermission && mounted) {
      final granted = await di.sl<PermissionService>().requestWithDialog(
        context,
        AppPermission.location,
      );
      if (!granted || !mounted) return;
    }
    setState(() => _isLoadingUserLocation = true);
    final result = await _locationService.getCurrentPosition();
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
    final uri = _mapsDestinationUri();
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No address or location to open')),
        );
      }
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  Future<void> _openDirections() async {
    final uri = _mapsDestinationUri();
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No address or location for directions')),
        );
      }
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions')),
      );
    }
  }

  /// Coordinates when valid; otherwise search by address.
  Uri? _mapsDestinationUri() {
    if (_showInlineMap &&
        isValidBusinessMapCoordinate(_targetLat, _targetLng)) {
      final lat = _targetLat;
      final lng = _targetLng;
      if (Platform.isIOS) {
        return Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d');
      }
      return Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
    }
    final q = widget.businessAddress?.trim() ?? '';
    if (q.isEmpty || q.toLowerCase() == 'address not available') {
      return null;
    }
    final encoded = Uri.encodeComponent(q);
    if (Platform.isIOS) {
      return Uri.parse('https://maps.apple.com/?q=$encoded');
    }
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );
  }

  Future<void> _zoomIn() async {
    await _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    await _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  Future<void> _recenterOnBusiness() async {
    if (!_showInlineMap) return;
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _businessPosition, zoom: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          PopupMenuButton<MapType>(
            icon: const Icon(Icons.layers),
            tooltip: 'Map type',
            onSelected: (type) {
              if (_showInlineMap) setState(() => _mapType = type);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: MapType.normal,
                child: Text('Standard'),
              ),
              PopupMenuItem(
                value: MapType.satellite,
                child: Text('Satellite'),
              ),
              PopupMenuItem(
                value: MapType.hybrid,
                child: Text('Hybrid (satellite + labels)'),
              ),
              PopupMenuItem(
                value: MapType.terrain,
                child: Text('Terrain'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openInExternalMaps,
          ),
        ],
      ),
      body: _resolvingGeocode
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                if (_showInlineMap)
                  Positioned.fill(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _businessPosition,
                        zoom: 15,
                      ),
                      mapType: _mapType,
                      padding: EdgeInsets.only(bottom: 200 + bottomInset),
                      markers: {
                        Marker(
                          markerId: MarkerId(widget.businessId),
                          position: _businessPosition,
                          infoWindow: InfoWindow(
                            title: widget.businessName ?? 'Business',
                            snippet: widget.businessAddress,
                          ),
                        ),
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                      compassEnabled: true,
                      mapToolbarEnabled: false,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        unawaited(
                          controller.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: _businessPosition,
                                zoom: 15,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Positioned.fill(
                    child: Container(
                      color: AppColors.backgroundLight,
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 64,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Map preview unavailable',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This listing has no saved coordinates yet. Open Apple or Google Maps using the address below.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              text: 'Open in Maps',
                              onPressed: _openInExternalMaps,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_showInlineMap)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Zoom in',
                            onPressed: _zoomIn,
                            icon: const Icon(Icons.add,
                                color: AppColors.textPrimary),
                          ),
                          const Divider(height: 1),
                          IconButton(
                            tooltip: 'Zoom out',
                            onPressed: _zoomOut,
                            icon: const Icon(Icons.remove,
                                color: AppColors.textPrimary),
                          ),
                          const Divider(height: 1),
                          IconButton(
                            tooltip: 'Center on business',
                            onPressed: _recenterOnBusiness,
                            icon: const Icon(Icons.place,
                                color: AppColors.brandPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_showInlineMap)
                  Positioned(
                    bottom: 200,
                    right: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'my_location',
                      onPressed:
                          _isLoadingUserLocation ? null : _onMyLocationPressed,
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
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
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
                          widget.businessName ?? 'Business',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle ??
                              widget.businessAddress ??
                              'Tap Directions to navigate',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AppButton(
                              text: 'Directions',
                              width: 120,
                              height: 36,
                              onPressed: _openDirections,
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
