import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/job_application.dart';

/// Detail view of a single job application (job seeker's own application).
class MyApplicationDetailPage extends StatelessWidget {
  const MyApplicationDetailPage({
    super.key,
    required this.application,
  });

  final JobApplication application;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Application Details'),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppResources.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.jobTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    application.companyName,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StatusChip(status: application.status),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (application.screeningAnswers.isNotEmpty) ...[
              const Text(
                'Screening',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              AppCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: application.screeningAnswers.entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${e.key}\n${e.value}',
                            style: const TextStyle(fontSize: 14, height: 1.45),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (application.coverLetter != null && application.coverLetter!.isNotEmpty) ...[
              const Text(
                'Cover Letter',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              AppCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                child: Text(
                  application.coverLetter!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (application.resumeUrl != null && application.resumeUrl!.isNotEmpty) ...[
              const Text(
                'Resume',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              AppCard(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.description, color: AppColors.brandPrimary),
                  title: const Text('Resume'),
                  subtitle: const Text('PDF'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined),
                        onPressed: () => _launchUrl(application.resumeUrl!),
                        tooltip: 'Preview resume',
                      ),
                      IconButton(
                        icon: const Icon(Icons.download_outlined),
                        onPressed: () => _launchUrl(application.resumeUrl!),
                        tooltip: 'Download resume',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (application.email.isNotEmpty || application.phoneNumber.isNotEmpty) ...[
              const Text(
                'Contact Info',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              AppCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (application.email.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _launchUrl('mailto:${application.email}'),
                                child: Text(
                                  application.email,
                                  style: const TextStyle(
                                    color: AppColors.brandPrimary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (application.phoneNumber.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _launchUrl('tel:${application.phoneNumber}'),
                              child: Text(
                                application.phoneNumber,
                                style: const TextStyle(
                                  color: AppColors.brandPrimary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.color.withValues(alpha: 0.5)),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: info.color,
        ),
      ),
    );
  }

  ({String label, Color color}) _statusInfo(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return (label: 'Application Sent', color: AppColors.info);
      case ApplicationStatus.reviewed:
      case ApplicationStatus.shortlisted:
        return (label: 'Under Review', color: AppColors.warning);
      case ApplicationStatus.accepted:
        return (label: 'Interview Scheduled', color: AppColors.brandPrimary);
      case ApplicationStatus.hired:
        return (label: 'Hired', color: AppColors.success);
      case ApplicationStatus.rejected:
        return (label: 'Closed', color: AppColors.textSecondary);
    }
  }
}
