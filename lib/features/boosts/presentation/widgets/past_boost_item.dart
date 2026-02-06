import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../domain/entities/boost_option.dart';
import '../../domain/entities/past_boost.dart';

class PastBoostItem extends StatelessWidget {
  const PastBoostItem({
    super.key,
    required this.boost,
    required this.onReBoost,
  });

  final PastBoost boost;
  final VoidCallback onReBoost;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
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
            child: Icon(
              _iconForType(boost.type),
              color: AppColors.brandPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppResources.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boost.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  boost.dateRange,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  boost.views,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: onReBoost,
                  child: const Text(
                    'RE-BOOST',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
