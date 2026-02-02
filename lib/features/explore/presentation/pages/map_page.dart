import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

class MapPage extends StatelessWidget {
  final String businessId;
  final double latitude;
  final double longitude;

  const MapPage({
    super.key,
    required this.businessId,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              // Open in external map app
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Placeholder for map - In production, use google_maps_flutter or similar
          Container(
            color: AppColors.backgroundGrey,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'Map View',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: $latitude, Lng: $longitude',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // User location button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                // Center map on user location
              },
              backgroundColor: AppColors.brandPrimary,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          // Business info card
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
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Addis Ababa Restaur',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ethiopian Cuisine • 0.5 mi',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      const Text(
                        '4.8 (120)',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      AppButton(
                        text: 'Directions',
                        width: 120,
                        height: 36,
                        onPressed: () {
                          // Open directions
                        },
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
