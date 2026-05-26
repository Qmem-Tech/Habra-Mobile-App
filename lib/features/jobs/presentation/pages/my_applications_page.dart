import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/resources/app_assets.dart';
import '../../domain/entities/job_application.dart';
import '../bloc/job_applications_cubit.dart';
import '../bloc/job_applications_state.dart';
import 'my_application_detail_page.dart';

/// Community member's job applications list with status (Application Sent, Under Review, Interview Scheduled).
class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<JobApplicationsCubit>().loadApplications(activeOnly: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Applications'),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocBuilder<JobApplicationsCubit, JobApplicationsState>(
        builder: (context, state) {
          if (state is JobApplicationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is JobApplicationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: AppResources.spacingM),
                  AppButton(
                    text: 'Retry',
                    onPressed: () => context.read<JobApplicationsCubit>().loadApplications(activeOnly: false),
                  ),
                ],
              ),
            );
          }
          if (state is JobApplicationsLoaded && state.applications.isEmpty) {
            return EmptyStateWidget(
              illustrationPath: AppAssets.noApplications,
              title: 'No applications yet',
              message: 'When you apply for jobs, they\'ll show here.',
              buttonLabel: 'Browse Jobs',
              onButtonTap: () => Navigator.pop(context),
            );
          }
          if (state is JobApplicationsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<JobApplicationsCubit>().loadApplications(activeOnly: false);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(AppResources.spacingM),
                itemCount: state.applications.length,
                itemBuilder: (context, index) {
                  return _ApplicationCard(
                    application: state.applications[index],
                    onViewApplication: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyApplicationDetailPage(
                            application: state.applications[index],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final JobApplication application;
  final VoidCallback onViewApplication;

  const _ApplicationCard({
    required this.application,
    required this.onViewApplication,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(application.status);
    final appliedStr = _formatDate(application.appliedDate);

    return Container(
      margin: const EdgeInsets.only(bottom: AppResources.spacingM),
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                    _StatusChip(
                      label: statusInfo.label,
                      color: statusInfo.color,
                    ),
                    const SizedBox(height: AppResources.spacingS),
                    Text(
                      application.jobTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      application.companyName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      'Applied $appliedStr',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppResources.radiusM),
                ),
                child: const Icon(Icons.business, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppResources.spacingM),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'View Application',
              height: AppResources.buttonHeightS,
              backgroundColor: statusInfo.isPrimary
                  ? AppColors.brandPrimary
                  : AppColors.backgroundGrey,
              textColor: statusInfo.isPrimary
                  ? AppColors.textOnPrimary
                  : AppColors.textPrimary,
              onPressed: onViewApplication,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  ({String label, Color color, bool isPrimary}) _statusInfo(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return (label: 'Application Sent', color: AppColors.info, isPrimary: false);
      case ApplicationStatus.reviewed:
      case ApplicationStatus.shortlisted:
        return (label: 'Under Review', color: AppColors.warning, isPrimary: false);
      case ApplicationStatus.accepted:
        return (label: 'Interview Scheduled', color: AppColors.brandPrimary, isPrimary: true);
      case ApplicationStatus.hired:
        return (label: 'Hired', color: AppColors.success, isPrimary: true);
      case ApplicationStatus.rejected:
        return (label: 'Closed', color: AppColors.textSecondary, isPrimary: false);
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppResources.spacingS,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppResources.radiusXXL),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
