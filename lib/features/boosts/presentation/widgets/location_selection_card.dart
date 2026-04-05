import 'package:flutter/material.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/boost_location.dart';

/// Gold star for ratings (matches boost location mock).
const Color _kRatingStarGold = Color(0xFFFFC107);

/// Card used on the "Select Location" screen to pick one or more branches.
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
          color: isSelected
              ? AppColors.backgroundWhite
              : AppColors.backgroundLight.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(AppResources.radiusL),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : AppColors.backgroundGrey.withValues(alpha: 0.45),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.18),
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
                      Icon(
                        Icons.remove_red_eye_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location.viewsPerMonth,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: _kRatingStarGold,
                      ),
                      const SizedBox(width: 2),
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
            _SelectionDot(selected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    const size = 26.0;
    if (selected) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandPrimary,
        ),
        child: const Icon(
          Icons.check,
          size: 16,
          color: AppColors.textOnPrimary,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.backgroundGrey,
          width: 2,
        ),
        color: Colors.transparent,
      ),
    );
  }
}
