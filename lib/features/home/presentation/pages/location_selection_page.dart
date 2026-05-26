import 'package:flutter/material.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/location_entity.dart';

class LocationSelectionPage extends StatefulWidget {
  const LocationSelectionPage({super.key});

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<LocationEntity> _locations = const [
    LocationEntity(
      id: '1',
      city: 'Washington',
      state: 'D.C.',
      country: 'USA',
    ),
    LocationEntity(
      id: '2',
      city: 'Dallas',
      state: 'TX',
      country: 'USA',
    ),
    LocationEntity(
      id: '3',
      city: 'Atlanta',
      state: 'GA',
      country: 'USA',
    ),
    LocationEntity(
      id: '4',
      city: 'Seattle',
      state: 'WA',
      country: 'USA',
    ),
    LocationEntity(
      id: '5',
      city: 'Denver',
      state: 'CO',
      country: 'USA',
    ),
    LocationEntity(
      id: '6',
      city: 'Las Vegas',
      state: 'NV',
      country: 'USA',
    ),
    LocationEntity(
      id: '7',
      city: 'Portland',
      state: 'OR',
      country: 'USA',
    ),
  ];

  LocationEntity? _selectedLocation;
  LocationEntity? _currentLocation;
  bool _isLoadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation({bool requestPermissionFirst = false}) async {
    if (requestPermissionFirst && mounted) {
      final granted = await di.sl<PermissionService>().requestWithDialog(
        context,
        AppPermission.location,
      );
      if (!granted || !mounted) return;
    }
    final result = await di.sl<LocationService>().getCurrentLocation();
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _locationError = failure.message;
          _isLoadingLocation = false;
          _currentLocation = null;
          _selectedLocation = _locations.isNotEmpty ? _locations.first : null;
        });
      },
      (location) {
        setState(() {
          _currentLocation = location;
          _selectedLocation = location;
          _isLoadingLocation = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCurrentLocationOption(),
            Expanded(
              child: _buildLocationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Select Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the close button
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.brandPrimary),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search for a city or region',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  // TODO: Implement search filtering
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationOption() {
    if (_isLoadingLocation) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.backgroundGrey),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'Detecting your location...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentLocation == null) {
      if (_locationError != null) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => _loadCurrentLocation(requestPermissionFirst: true),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.backgroundGrey),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_off, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Use Current Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _locationError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to try again',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedLocation = _currentLocation);
          _returnSelectedLocation();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brandPrimary),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.my_location,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Use Current Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detected: ${_currentLocation!.fullDisplayName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationList() {
    final filteredLocations = _searchController.text.isEmpty
        ? _locations
        : _locations
            .where((loc) =>
                loc.city.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                (loc.state != null &&
                    loc.state!.toLowerCase().contains(_searchController.text.toLowerCase())))
            .toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredLocations.length,
      itemBuilder: (context, index) {
        final location = filteredLocations[index];
        final isSelected = location.id == _selectedLocation?.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedLocation = location;
            });
            _returnSelectedLocation();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.brandPrimary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.brandPrimary : AppColors.backgroundGrey,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    location.fullDisplayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check,
                    color: Colors.white,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _returnSelectedLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, _selectedLocation);
    }
  }
}
