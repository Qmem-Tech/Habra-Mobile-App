import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../domain/entities/boost_option.dart';

class BoostOptionCard extends StatelessWidget {
  const BoostOptionCard({
    super.key,
    required this.option,
    required this.onTap,
  });

  final BoostOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppResources.spacingM),
      child: Material(
        color: AppColors.backgroundLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppResources.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppResources.spacingM),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.priceLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppResources.radiusM),
                  ),
                  child: Icon(
                    _iconForType(option.type),
                    color: AppColors.brandPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForType(BoostOptionType type) {
    switch (type) {
      case BoostOptionType.businessListing:
        return Icons.storefront;
      case BoostOptionType.deal:
        return Icons.local_offer;
      case BoostOptionType.job:
        return Icons.work_outline;
    }
  }
}
