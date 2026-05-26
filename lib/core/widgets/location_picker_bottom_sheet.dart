import 'package:flutter/material.dart';

import '../../injection/injection_container.dart' as di;
import '../resources/app_resources.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';

/// A comprehensive list of major US metropolitan areas.
/// Shared across the app for consistency.
const List<String> kPopularUSCities = [
  'Atlanta, GA',
  'Austin, TX',
  'Baltimore, MD',
  'Boston, MA',
  'Charlotte, NC',
  'Chicago, IL',
  'Cincinnati, OH',
  'Cleveland, OH',
  'Columbus, OH',
  'Dallas, TX',
  'Denver, CO',
  'Detroit, MI',
  'Fort Worth, TX',
  'Houston, TX',
  'Indianapolis, IN',
  'Jacksonville, FL',
  'Kansas City, MO',
  'Las Vegas, NV',
  'Los Angeles, CA',
  'Louisville, KY',
  'Memphis, TN',
  'Miami, FL',
  'Milwaukee, WI',
  'Minneapolis, MN',
  'Nashville, TN',
  'New Orleans, LA',
  'New York, NY',
  'Newark, NJ',
  'Oakland, CA',
  'Oklahoma City, OK',
  'Orlando, FL',
  'Philadelphia, PA',
  'Phoenix, AZ',
  'Pittsburgh, PA',
  'Portland, OR',
  'Raleigh, NC',
  'Richmond, VA',
  'Sacramento, CA',
  'Salt Lake City, UT',
  'San Antonio, TX',
  'San Diego, CA',
  'San Francisco, CA',
  'San Jose, CA',
  'Seattle, WA',
  'St. Louis, MO',
  'Tampa, FL',
  'Tucson, AZ',
  'Virginia Beach, VA',
  'Washington, D.C.',
];

/// Bottom sheet that lets the user pick a location by searching a list
/// of major US cities, using the device's current location, or geocoding
/// a custom address.
///
/// Returns the chosen display name (e.g. "Dallas, TX") via [Navigator.pop].
class LocationPickerBottomSheet extends StatefulWidget {
  const LocationPickerBottomSheet({super.key, this.currentValue});

  /// Pre-highlight value if it matches a city in the list.
  final String? currentValue;

  /// Convenience helper to show the bottom sheet and await the result.
  static Future<String?> show(BuildContext context, {String? currentValue}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppResources.radiusXL)),
      ),
      builder: (_) => LocationPickerBottomSheet(currentValue: currentValue),
    );
  }

  @override
  State<LocationPickerBottomSheet> createState() => _LocationPickerBottomSheetState();
}

class _LocationPickerBottomSheetState extends State<LocationPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCities = kPopularUSCities;
  bool _isLocating = false;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCities = kPopularUSCities;
      } else {
        _filteredCities = kPopularUSCities
            .where((c) => c.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    final result = await di.sl<LocationService>().getCurrentLocation();
    if (!mounted) return;
    setState(() => _isLocating = false);
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
        );
      },
      (location) => Navigator.pop(context, location.fullDisplayName),
    );
  }

  Future<void> _geocodeCustomQuery() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isGeocoding = true);
    final geoResult = await di.sl<LocationService>().geocodeToAddress(query);
    if (!mounted) return;
    setState(() => _isGeocoding = false);
    geoResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
        );
      },
      (address) {
        final parts = <String>[
          if (address.city != null) address.city!,
          if (address.state != null) address.state!,
        ];
        final display = parts.isNotEmpty ? parts.join(', ') : query;
        Navigator.pop(context, display);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final showGeocodeTile = query.isNotEmpty && _filteredCities.isEmpty;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppResources.spacingL,
                vertical: AppResources.spacingS,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Location',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingL),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search city or address...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppResources.radiusM),
                    borderSide: const BorderSide(color: AppColors.backgroundGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppResources.radiusM),
                    borderSide: const BorderSide(color: AppColors.backgroundGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppResources.radiusM),
                    borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: AppResources.spacingS),

            // Results list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingL),
                children: [
                  // "Use current location" tile
                  _ActionTile(
                    icon: Icons.my_location,
                    label: 'Use current location',
                    isLoading: _isLocating,
                    onTap: _isLocating ? null : _useCurrentLocation,
                  ),

                  const Divider(height: 1),

                  // Geocode fallback when no predefined city matches
                  if (showGeocodeTile) ...[
                    _ActionTile(
                      icon: Icons.travel_explore,
                      label: 'Search for "$query"',
                      isLoading: _isGeocoding,
                      onTap: _isGeocoding ? null : _geocodeCustomQuery,
                    ),
                    const Divider(height: 1),
                  ],

                  // City list
                  for (final city in _filteredCities)
                    _CityTile(
                      city: city,
                      isSelected: widget.currentValue == city,
                      onTap: () => Navigator.pop(context, city),
                    ),

                  // Geocode option shown at bottom when there ARE filtered results
                  // but the typed query doesn't exactly match a city
                  if (query.isNotEmpty &&
                      _filteredCities.isNotEmpty &&
                      !_filteredCities.any((c) => c.toLowerCase() == query.toLowerCase())) ...[
                    const Divider(height: 1),
                    _ActionTile(
                      icon: Icons.travel_explore,
                      label: 'Search for "$query" instead',
                      isLoading: _isGeocoding,
                      onTap: _isGeocoding ? null : _geocodeCustomQuery,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable row for an action (current location / geocode search).
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    this.isLoading = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.brandPrimary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}

/// Tappable row for a predefined city.
class _CityTile extends StatelessWidget {
  const _CityTile({
    required this.city,
    required this.isSelected,
    required this.onTap,
  });

  final String city;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.location_city, color: AppColors.textSecondary, size: 20),
      title: Text(
        city,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? AppColors.brandPrimary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.brandPrimary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
