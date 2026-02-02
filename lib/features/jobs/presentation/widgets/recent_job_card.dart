import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/job_listing.dart';

class RecentJobCard extends StatelessWidget {
  final JobListing job;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;

  const RecentJobCard({
    super.key,
    required this.job,
    this.onTap,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Logo
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: job.companyLogoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        job.companyLogoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.business,
                            color: AppColors.textSecondary,
                            size: 28,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.business,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 12),
            // Job Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.companyName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(job.jobType),
                      if (job.salary != null) _buildChip(job.salary!),
                      if (job.location != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              job.location!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Bookmark & Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onBookmark,
                  child: Icon(
                    job.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: job.isBookmarked
                        ? AppColors.brandSecondary
                        : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  job.timeAgo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
