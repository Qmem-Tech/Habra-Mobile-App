import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';
import '../resources/app_resources.dart';
import 'app_button.dart';
import '../services/location_service.dart';
import '../domain/business_address_data.dart';
import '../permissions/app_permission.dart';
import '../services/permission_service.dart';
import '../../injection/injection_container.dart' as di;

/// Full-screen map for picking a business address. User taps to set pin, reverse geocodes to fill address.
class AddressMapPickerPage extends StatefulWidget {
  const AddressMapPickerPage({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  final double? initialLat;
  final double? initialLng;

  @override
  State<AddressMapPickerPage> createState() => _AddressMapPickerPageState();
}

class _AddressMapPickerPageState extends State<AddressMapPickerPage> {
  GoogleMapController? _mapController;
  final LocationService _locationService = di.sl<LocationService>();
  bool _isLoadingUserLocation = false;
  bool _isGeocoding = false;
  double? _selectedLat;
  double? _selectedLng;
  BusinessAddressData? _addressData;

  static const double _defaultLat = 38.9072;
  static const double _defaultLng = -77.0369;

  LatLng get _initialPosition {
    if (widget.initialLat != null && widget.initialLng != null) {
      return LatLng(widget.initialLat!, widget.initialLng!);
    }
    if (_selectedLat != null && _selectedLng != null) {
      return LatLng(_selectedLat!, _selectedLng!);
    }
    return const LatLng(_defaultLat, _defaultLng);
  }

  Set<Marker> get _markers {
    if (_selectedLat == null || _selectedLng == null) return {};
    return {
      Marker(
        markerId: const MarkerId('picked'),
        position: LatLng(_selectedLat!, _selectedLng!),
        draggable: true,
        onDragEnd: (pos) => _onPositionTapped(pos.latitude, pos.longitude),
      ),
    };
  }

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLat;
    _selectedLng = widget.initialLng;
    if (_selectedLat != null && _selectedLng != null) {
      _reverseGeocode(_selectedLat!, _selectedLng!);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _onMapTapped(LatLng position) async {
    await _onPositionTapped(position.latitude, position.longitude);
  }

  Future<void> _onPositionTapped(double lat, double lng) async {
    setState(() {
      _selectedLat = lat;
      _selectedLng = lng;
    });
    await _reverseGeocode(lat, lng);
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() => _isGeocoding = true);
    final result = await _locationService.reverseGeocodeToAddress(lat, lng);
    if (!mounted) return;
    setState(() {
      _isGeocoding = false;
      _addressData = result.fold((_) => null, (a) => a);
    });
  }

  Future<void> _onMyLocationPressed() async {
    final granted = await di.sl<PermissionService>().requestWithDialog(
      context,
      AppPermission.location,
    );
    if (!granted || !mounted) return;
    setState(() => _isLoadingUserLocation = true);
    final result = await _locationService.getCurrentPosition();
    setState(() => _isLoadingUserLocation = false);
    result.fold(
      (f) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.message)),
          );
        }
      },
      (position) {
        _onPositionTapped(position.latitude, position.longitude);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      },
    );
  }

  void _onConfirm() {
    if (_addressData == null) return;
    Navigator.pop(context, _addressData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location on map'),
        actions: [
          if (_addressData != null)
            TextButton(
              onPressed: _onConfirm,
              child: const Text('Use this address'),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 15,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _mapController = c,
            onTap: _onMapTapped,
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'addr_my_loc',
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
              padding: const EdgeInsets.all(AppResources.spacingM),
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
                  if (_isGeocoding)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_addressData != null) ...[
                    Text(
                      _formatAddress(_addressData!),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'Use this address',
                      onPressed: _onConfirm,
                    ),
                  ] else
                    Text(
                      'Tap on the map to set your business location',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(BusinessAddressData a) {
    final parts = <String>[];
    if (a.street != null && a.street!.isNotEmpty) parts.add(a.street!);
    if (a.city != null && a.city!.isNotEmpty) parts.add(a.city!);
    if (a.state != null && a.state!.isNotEmpty) parts.add(a.state!);
    if (a.zipCode != null && a.zipCode!.isNotEmpty) parts.add(a.zipCode!);
    return parts.join(', ');
  }
}
