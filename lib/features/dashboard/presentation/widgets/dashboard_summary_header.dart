import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';

/// Summary header showing key metrics (deals, jobs, reviews) at a glance.
class DashboardSummaryHeader extends StatelessWidget {
  const DashboardSummaryHeader({
    super.key,
    required this.activeDealsCount,
    required this.activeJobsCount,
    this.rating,
    this.reviewCount,
    this.onDealsTap,
    this.onJobsTap,
    this.onReviewsTap,
  });

  final int activeDealsCount;
  final int activeJobsCount;
  final double? rating;
  final int? reviewCount;
  final VoidCallback? onDealsTap;
  final VoidCallback? onJobsTap;
  final VoidCallback? onReviewsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppResources.spacingM, 12, AppResources.spacingM, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandPrimary.withValues(alpha: 0.08),
            AppColors.brandSecondary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              icon: Icons.sell_outlined,
              iconColor: AppColors.brandSecondary,
              value: '$activeDealsCount',
              label: 'Active Deals',
              onTap: onDealsTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              icon: Icons.work_outline,
              iconColor: AppColors.brandPrimary,
              value: '$activeJobsCount',
              label: 'Open Jobs',
              onTap: onJobsTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              icon: Icons.star_outline,
              iconColor: AppColors.brandSecondary,
              value: rating != null ? rating!.toStringAsFixed(1) : '—',
              label: '${reviewCount ?? 0} Reviews',
              onTap: onReviewsTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
