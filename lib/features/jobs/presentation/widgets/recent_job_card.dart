import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/job_listing.dart';
import 'job_company_logo.dart';

class RecentJobCard extends StatelessWidget {
  static const Color _bookmarkGold = Color(0xFFFFC107);

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
    final locationLabel = (job.location?.trim().isNotEmpty ?? false)
        ? job.location!.trim()
        : 'Location TBD';

    return Material(
      color: AppColors.backgroundWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  JobCompanyLogo(
                    url: job.companyLogoUrl,
                    size: 48,
                    borderRadius: 8,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.companyName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onPressed: onBookmark,
                    icon: Icon(
                      job.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: job.isBookmarked
                          ? _bookmarkGold
                          : AppColors.textSecondary,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final rowW = constraints.maxWidth;
                  return Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: rowW),
                        child: _buildChip(job.jobType),
                      ),
                      if (job.salary != null)
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: rowW),
                          child: _buildChip(job.salary!),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 3,
                    child: Text(
                      locationLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (job.timeAgo.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: Text(
                        job.timeAgo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.backgroundGrey.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
