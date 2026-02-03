import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/dashboard_job.dart';
import '../widgets/empty_state_widget.dart';
import '../../../../core/resources/app_assets.dart';

class DashboardJobsTab extends StatelessWidget {
  const DashboardJobsTab({
    super.key,
    required this.jobs,
    required this.onCreateJob,
    required this.onViewApplicants,
  });

  final List<DashboardJob> jobs;
  final VoidCallback onCreateJob;
  final void Function(DashboardJob job) onViewApplicants;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return EmptyStateWidget(
        illustrationPath: AppAssets.dashboardNoJobs,
        title: 'No job posts yet',
        description: 'Create a job post today to start finding your next great hire within the community.',
        actionLabel: 'Post A Job',
        onAction: onCreateJob,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 8, AppResources.spacingM, 100),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _JobCard(
          job: job,
          onViewApplicants: () => onViewApplicants(job),
          onEdit: () {},
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.onViewApplicants,
    required this.onEdit,
  });

  final DashboardJob job;
  final VoidCallback onViewApplicants;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              job.jobType,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              job.location,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_money, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              job.salaryDisplay,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    job.postedTimeAgo,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.brandPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  icon: Icons.visibility_outlined,
                  value: '${job.viewsCount} Views',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricChip(
                  icon: Icons.people_outline,
                  value: '${job.applicantsCount} Applicants',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AppButton(
                  text: 'View Applicants',
                  onPressed: onViewApplicants,
                  icon: Icons.arrow_forward,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: AppResources.buttonHeightM,
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: AppColors.textSecondary),
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Icon(Icons.edit_outlined, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
