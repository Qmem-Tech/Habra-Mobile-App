import 'package:flutter/material.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/boost_location.dart';

/// Card used on the "Select Location" screen to pick a branch to boost.
class LocationSelectionCard extends StatelessWidget {
  const LocationSelectionCard({
    super.key,
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  final BoostLocation location;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppResources.spacingM),
        padding: const EdgeInsets.all(AppResources.spacingM),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppResources.radiusL),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : AppColors.backgroundGrey,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppResources.radiusM),
              ),
              child: const Icon(
                Icons.storefront,
                color: AppColors.brandPrimary,
                size: 26,
              ),
            ),
            const SizedBox(width: AppResources.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.address,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.remove_red_eye_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        location.viewsPerMonth,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.star,
                          size: 14, color: AppColors.warning), // consistent rating color
                      const SizedBox(width: 4),
                      Text(
                        location.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppResources.spacingS),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? AppColors.brandPrimary : AppColors.backgroundGrey,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: AppColors.textOnPrimary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
