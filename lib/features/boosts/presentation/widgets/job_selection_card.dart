import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../dashboard/domain/entities/dashboard_job.dart';

class JobSelectionCard extends StatelessWidget {
  const JobSelectionCard({
    super.key,
    required this.job,
    required this.isSelected,
    required this.onTap,
  });

  final DashboardJob job;
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
              ? AppColors.brandPrimary.withValues(alpha: 0.06)
              : AppColors.backgroundLight.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppResources.radiusL),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : Colors.transparent,
            width: 2,
          ),
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
                Icons.restaurant,
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
                    job.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    job.employerName != null
                        ? '${job.employerName}, ${job.location}'
                        : job.location,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        job.applicantsDisplay,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.schedule_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        job.postedDisplay,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
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
