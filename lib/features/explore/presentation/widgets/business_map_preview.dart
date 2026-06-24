import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/location/map_coordinates.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/business_detail.dart';
import '../pages/map_page.dart';

String? _geocodeQueryForBusiness(BusinessDetail business) {
  final addr = business.fullAddress.trim();
  if (addr.isEmpty || addr.toLowerCase() == 'address not available') {
    return null;
  }
  return addr;
}

/// Small map preview for business listings: DB coordinates or forward-geocoded address.
class BusinessMapPreview extends StatefulWidget {
  const BusinessMapPreview({
    super.key,
    required this.business,
    this.height = 150,
    this.showDirectionsButton = true,
  });

  final BusinessDetail business;
  final double height;
  final bool showDirectionsButton;

  @override
  State<BusinessMapPreview> createState() => _BusinessMapPreviewState();
}

class _BusinessMapPreviewState extends State<BusinessMapPreview> {
  LatLng? _position;
  bool _loading = true;
  String? _geocodeError;

  double? get _resolvedLat => _position?.latitude;
  double? get _resolvedLng => _position?.longitude;

  @override
  void initState() {
    super.initState();
    final b = widget.business;
    if (isValidMapCoordinate(b.latitude, b.longitude)) {
      _position = LatLng(b.latitude, b.longitude);
      _loading = false;
    } else {
      final q = _geocodeQueryForBusiness(b);
      if (q != null && q.trim().isNotEmpty) {
        _resolveGeocode(q.trim());
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
    final lat = _resolvedLat ?? widget.business.latitude;
    final lng = _resolvedLng ?? widget.business.longitude;
    final Uri url;
    if (isValidMapCoordinate(lat, lng)) {
      if (Platform.isIOS) {
        url = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d');
      } else {
        url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
        );
      }
    } else {
      final encoded = Uri.encodeComponent(widget.business.fullAddress);
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
    final lat = _resolvedLat ?? widget.business.latitude;
    final lng = _resolvedLng ?? widget.business.longitude;
    final b = widget.business;
    final subtitle = b.categories.isNotEmpty
        ? '${b.categories.first.displayName} • ${b.rating.toStringAsFixed(1)} (${b.reviewCount})'
        : null;
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MapPage(
          businessId: b.id,
          latitude: lat,
          longitude: lng,
          businessName: b.name,
          businessAddress: b.fullAddress,
          subtitle: subtitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.business;

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
              b.fullAddress,
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
                        markerId: MarkerId(b.id),
                        position: position,
                        infoWindow: InfoWindow(
                          title: b.name,
                          snippet: b.fullAddress,
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
