import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/event_detail.dart';
import '../pages/event_map_page.dart';

/// Small map preview for event location. Shows map when lat/lng available.
class EventMapPreview extends StatelessWidget {
  const EventMapPreview({
    super.key,
    required this.event,
    this.height = 200,
    this.showDirectionsButton = true,
  });

  final EventDetail event;
  final double height;
  final bool showDirectionsButton;

  bool get _hasLocation =>
      event.latitude != null && event.longitude != null;

  LatLng get _position =>
      LatLng(event.latitude!, event.longitude!);

  Future<void> _openInMaps(BuildContext context) async {
    final lat = event.latitude!;
    final lng = event.longitude!;
    final Uri url;
    if (Platform.isIOS) {
      url = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d');
    } else {
      url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    }
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLocation) {
      return Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.backgroundGrey),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              event.fullAddress,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventMapPage(event: event),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _position,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId(event.id),
                        position: _position,
                        infoWindow: InfoWindow(
                          title: event.venue,
                          snippet: event.fullAddress,
                        ),
                      ),
                    },
                    myLocationEnabled: true,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventMapPage(event: event),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fullscreen, size: 18, color: AppColors.brandPrimary),
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
        if (showDirectionsButton) ...[
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
