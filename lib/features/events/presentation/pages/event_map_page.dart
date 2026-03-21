import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/event_detail.dart';

/// Full-screen map for event location with directions option.
class EventMapPage extends StatefulWidget {
  const EventMapPage({
    super.key,
    required this.event,
  });

  final EventDetail event;

  @override
  State<EventMapPage> createState() => _EventMapPageState();
}

class _EventMapPageState extends State<EventMapPage> {
  GoogleMapController? _mapController;
  bool _isLoadingUserLocation = false;

  LatLng get _eventPosition =>
      LatLng(widget.event.latitude!, widget.event.longitude!);

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
    final lat = widget.event.latitude!;
    final lng = widget.event.longitude!;
    final Uri url;
    if (Platform.isIOS) {
      url = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d');
    } else {
      url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    }
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        text: 'Get Directions',
                        width: 140,
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
