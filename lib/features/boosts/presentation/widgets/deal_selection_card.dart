import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../dashboard/domain/entities/dashboard_deal.dart';

class DealSelectionCard extends StatelessWidget {
  const DealSelectionCard({
    super.key,
    required this.deal,
    required this.isSelected,
    required this.onTap,
  });

  final DashboardDeal deal;
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
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              child: Image.network(
                deal.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 70,
                  height: 70,
                  color: AppColors.backgroundLight,
                  child: const Icon(Icons.local_offer, color: AppColors.textTertiary),
                ),
              ),
            ),
            const SizedBox(width: AppResources.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (deal.merchantName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      deal.merchantName!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        deal.expiresInDays,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.brandPrimary : AppColors.backgroundGrey,
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
