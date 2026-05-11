import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/dashboard_job.dart';
import '../widgets/empty_state_widget.dart';
import '../../../../core/resources/app_assets.dart';

/// Mint-tint surfaces (dashboard jobs mock).
const Color _mintSurface = Color(0xFFE8F3EE);
const Color _statGraySurface = Color(0xFFF0F2F4);

class DashboardJobsTab extends StatelessWidget {
  const DashboardJobsTab({
    super.key,
    required this.jobs,
    this.filter,
    required this.onFilterChanged,
    required this.onCreateJob,
    required this.onViewApplicants,
    this.onEditJob,
    this.onDeleteJob,
  });

  final List<DashboardJob> jobs;
  final DashboardJobStatus? filter;
  final ValueChanged<DashboardJobStatus?> onFilterChanged;
  final VoidCallback onCreateJob;
  final void Function(DashboardJob job) onViewApplicants;
  final void Function(DashboardJob job)? onEditJob;
  final void Function(DashboardJob job)? onDeleteJob;

  @override
  Widget build(BuildContext context) {
    final activeCount = jobs.where((j) => j.status == DashboardJobStatus.open).length;
    final closedCount = jobs.where((j) => j.status == DashboardJobStatus.closed).length;
    final draftCount = jobs.where((j) => j.status == DashboardJobStatus.draft).length;
    final effectiveFilter = filter ?? DashboardJobStatus.open;
    final filteredJobs = jobs.where((j) => j.status == effectiveFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Active ($activeCount)',
                  selected: effectiveFilter == DashboardJobStatus.open,
                  onTap: () => onFilterChanged(DashboardJobStatus.open),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Closed ($closedCount)',
                  selected: effectiveFilter == DashboardJobStatus.closed,
                  onTap: () => onFilterChanged(DashboardJobStatus.closed),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Drafts ($draftCount)',
                  selected: effectiveFilter == DashboardJobStatus.draft,
                  onTap: () => onFilterChanged(DashboardJobStatus.draft),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filteredJobs.isEmpty
              ? EmptyStateWidget(
                  illustrationPath: AppAssets.dashboardNoJobs,
                  title: _emptyTitle(effectiveFilter),
                  description: _emptyDescription(effectiveFilter),
                  actionLabel: 'Post A Job',
                  onAction: onCreateJob,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 8, AppResources.spacingM, 100),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) {
                    final job = filteredJobs[index];
                    return _JobCard(
                      job: job,
                      onViewApplicants: () => onViewApplicants(job),
                      onEdit: onEditJob != null ? () => onEditJob!(job) : null,
                      onDelete: onDeleteJob != null ? () => onDeleteJob!(job) : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  static String _emptyTitle(DashboardJobStatus f) {
    switch (f) {
      case DashboardJobStatus.draft:
        return 'No draft jobs';
      case DashboardJobStatus.closed:
        return 'No closed jobs';
      case DashboardJobStatus.open:
        return 'No job posts yet';
    }
  }

  static String _emptyDescription(DashboardJobStatus f) {
    switch (f) {
      case DashboardJobStatus.draft:
        return 'Save a job as draft to continue editing later.';
      case DashboardJobStatus.closed:
        return 'Closed listings appear here for your records.';
      case DashboardJobStatus.open:
        return 'Create a job post today to start finding your next great hire within the community.';
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandPrimary : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.onViewApplicants,
    this.onEdit,
    this.onDelete,
  });

  final DashboardJob job;
  final VoidCallback onViewApplicants;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  String get _postedBadgeText {
    final t = job.postedTimeAgo.trim();
    if (t.toLowerCase().startsWith('posted')) return t;
    return 'Posted $t';
  }

  String get _salaryLine {
    final s = job.salaryDisplay.trim();
    if (s.isEmpty) return '—';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      backgroundColor: AppColors.backgroundWhite,
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (job.isDraft)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Draft',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _mintSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _postedBadgeText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetaPill(
                  icon: Icons.schedule_rounded,
                  label: job.jobType,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetaPill(
                  icon: Icons.location_on_outlined,
                  label: job.location,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetaPill(
                  icon: Icons.payments_outlined,
                  label: _salaryLine,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ViewsStatBlock(count: job.viewsCount),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ApplicantsStatBlock(count: job.applicantsCount),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onViewApplicants,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 0,
                      shadowColor: AppColors.brandPrimary.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Applicants',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: _statGraySurface,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onEdit,
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.edit_outlined,
                      color: onEdit != null ? AppColors.brandPrimary : AppColors.textTertiary,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: _statGraySurface,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onDelete,
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.delete_outline,
                      color: onDelete != null ? AppColors.error : AppColors.textTertiary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.brandPrimary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewsStatBlock extends StatelessWidget {
  const _ViewsStatBlock({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _statGraySurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.backgroundWhite,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.visibility_rounded,
              color: AppColors.brandPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Views',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantsStatBlock extends StatelessWidget {
  const _ApplicantsStatBlock({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _mintSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.28),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.brandPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_rounded,
              color: AppColors.textOnPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Applicants',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
