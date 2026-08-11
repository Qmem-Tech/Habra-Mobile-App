import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/location/map_coordinates.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection/injection_container.dart' as di;
import '../pages/map_page.dart';

/// Small map preview for a listing: DB coordinates or forward-geocoded address.
class ListingMapPreview extends StatefulWidget {
  const ListingMapPreview({
    super.key,
    required this.listingId,
    required this.name,
    required this.fullAddress,
    this.latitude,
    this.longitude,
    this.subtitle,
    this.height = 150,
    this.showDirectionsButton = true,
  });

  final String listingId;
  final String name;
  final String fullAddress;
  final double? latitude;
  final double? longitude;
  final String? subtitle;
  final double height;
  final bool showDirectionsButton;

  @override
  State<ListingMapPreview> createState() => _ListingMapPreviewState();
}

class _ListingMapPreviewState extends State<ListingMapPreview> {
  LatLng? _position;
  bool _loading = true;
  String? _geocodeError;

  double? get _resolvedLat => _position?.latitude;
  double? get _resolvedLng => _position?.longitude;

  @override
  void initState() {
    super.initState();
    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat != null && lng != null && isValidMapCoordinate(lat, lng)) {
      _position = LatLng(lat, lng);
      _loading = false;
    } else {
      final addr = widget.fullAddress.trim();
      if (addr.isNotEmpty && addr.toLowerCase() != 'address not available') {
        _resolveGeocode(addr);
      } else {
        _loading = false;
      }
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
        if (!isValidMapCoordinate(coords.lat, coords.lng)) {
          setState(() => _loading = false);
          return;
        }
        setState(() {
          _loading = false;
          _position = LatLng(coords.lat, coords.lng);
        });
      },
    );
  }

  Future<void> _openInMaps() async {
    final lat = _resolvedLat ?? widget.latitude;
    final lng = _resolvedLng ?? widget.longitude;
    final Uri url;
    if (lat != null && lng != null && isValidMapCoordinate(lat, lng)) {
      final dLat = lat;
      final dLng = lng;
      if (Platform.isIOS) {
        url = Uri.parse('https://maps.apple.com/?daddr=$dLat,$dLng&dirflg=d');
      } else {
        url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$dLat,$dLng',
        );
      }
    } else {
      final encoded = Uri.encodeComponent(widget.fullAddress);
      if (Platform.isIOS) {
        url = Uri.parse('https://maps.apple.com/?q=$encoded');
      } else {
        url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encoded',
        );
      }
    }
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openFullMap() {
    final position = _position;
    if (position == null) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MapPage(
          businessId: widget.listingId,
          latitude: position.latitude,
          longitude: position.longitude,
          businessName: widget.name,
          businessAddress: widget.fullAddress,
          subtitle: widget.subtitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.backgroundGrey),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              widget.fullAddress,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
              onPressed: _openInMaps,
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
          onTap: _openFullMap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
                    compassEnabled: false,
                    buildingsEnabled: true,
                    markers: {
                      Marker(
                        markerId: MarkerId(widget.listingId),
                        position: position,
                        infoWindow: InfoWindow(
                          title: widget.name,
                          snippet: widget.fullAddress,
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
                        onTap: _openFullMap,
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _openInMaps,
              icon: const Icon(Icons.directions, size: 20),
              label: const Text('Get directions'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
