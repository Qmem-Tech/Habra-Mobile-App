import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../domain/entities/applicant_detail.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';

Future<void> _openExternalUri(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class ApplicantDetailsPage extends StatelessWidget {
  const ApplicantDetailsPage({
    super.key,
    required this.applicantId,
    required this.jobId,
    required this.applicantName,
    required this.jobTitle,
    required this.jobSubtitle,
  });

  final String applicantId;
  final String jobId;
  final String applicantName;
  final String jobTitle;
  final String jobSubtitle;

  @override
  Widget build(BuildContext context) {
    return _ApplicantDetailsBody(
      applicantId: applicantId,
      jobId: jobId,
      applicantName: applicantName,
      jobTitle: jobTitle,
      jobSubtitle: jobSubtitle,
    );
  }
}

class _ApplicantDetailsBody extends StatefulWidget {
  const _ApplicantDetailsBody({
    required this.applicantId,
    required this.jobId,
    required this.applicantName,
    required this.jobTitle,
    required this.jobSubtitle,
  });

  final String applicantId;
  final String jobId;
  final String applicantName;
  final String jobTitle;
  final String jobSubtitle;

  @override
  State<_ApplicantDetailsBody> createState() => _ApplicantDetailsBodyState();
}

class _ApplicantDetailsBodyState extends State<_ApplicantDetailsBody> {
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    context
        .read<DashboardCubit>()
        .loadApplicantDetail(widget.applicantId, widget.jobId);
  }

  void _popAndRestoreApplicantsList(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    cubit.clearApplicantDetail();
    cubit.loadApplicants(widget.jobId, widget.jobTitle, widget.jobSubtitle);
    Navigator.pop(context);
  }

  Future<void> _onMessage(ApplicantDetail d) async {
    final subject = 'Regarding your application: ${d.appliedFor}';
    if (d.email != null && d.email!.trim().isNotEmpty) {
      final uri = Uri(
        scheme: 'mailto',
        path: d.email,
        queryParameters: {'subject': subject},
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    final phone = d.phone?.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone != null && phone.isNotEmpty) {
      final sms = Uri(scheme: 'sms', path: phone);
      if (await canLaunchUrl(sms)) {
        await launchUrl(sms);
        return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No email or phone on file to start a conversation.'),
      ),
    );
  }

  Future<void> _confirmAndUpdateStatus(
    BuildContext context,
    String nextStatus,
  ) async {
    final title =
        nextStatus == 'rejected' ? 'Reject applicant?' : 'Mark as hired?';
    final body = nextStatus == 'rejected'
        ? 'They will be marked as not selected for this role.'
        : 'This will mark them as hired for this job.';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(nextStatus == 'rejected' ? 'Reject' : 'Confirm'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _actionBusy = true);
    final success = await context.read<DashboardCubit>().updateJobApplicationStatus(
          applicationId: widget.applicantId,
          jobId: widget.jobId,
          status: nextStatus,
        );
    if (mounted) setState(() => _actionBusy = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextStatus == 'rejected'
                ? 'Applicant marked as not selected.'
                : 'Applicant marked as hired.',
          ),
        ),
      );
      _popAndRestoreApplicantsList(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update status. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _popAndRestoreApplicantsList(context),
        ),
        title: const Text(
          'Applicant Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is ApplicantDetailLoading) {
            return const HabraCircularLoader(fullScreen: true);
          }
          if (state is ApplicantDetailError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    AppButton(
                      text: 'Back',
                      onPressed: () => _popAndRestoreApplicantsList(context),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! ApplicantDetailLoaded) {
            return const Center(child: Text('No data'));
          }
          final d = state.detail;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileHeaderCard(detail: d),
                      const SizedBox(height: 20),
                      const Text(
                        'Cover Letter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _GreyContentCard(
                        child: Text(
                          d.coverLetter.trim().isEmpty
                              ? 'No cover letter submitted.'
                              : d.coverLetter,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Experience',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (d.experience.isEmpty)
                        _GreyContentCard(
                          child: Text(
                            'No experience details were provided with this application.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...d.experience.asMap().entries.map((e) {
                          final i = e.key;
                          final x = e.value;
                          final green = i.isEven;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _GreyContentCard(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: green
                                          ? AppColors.brandPrimary
                                              .withValues(alpha: 0.12)
                                          : AppColors.warning
                                              .withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      green
                                          ? Icons.local_cafe_outlined
                                          : Icons.storefront_outlined,
                                      color: green
                                          ? AppColors.brandPrimary
                                          : AppColors.warning,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          x.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${x.company} • ${x.employmentType}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          '${x.period} • ${x.duration}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 20),
                      const Text(
                        'Resume',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ResumeCard(
                        detail: d,
                        onView: () {
                          final url = d.resumeFileUrl;
                          if (url != null && url.isNotEmpty) {
                            _openExternalUri(url);
                          }
                        },
                        onDownload: () {
                          final url = d.resumeFileUrl;
                          if (url != null && url.isNotEmpty) {
                            _openExternalUri(url);
                          }
                        },
                      ),
                      if (d.isTerminalStatus) ...[
                        const SizedBox(height: 16),
                        _StatusBanner(detail: d),
                      ],
                    ],
                  ),
                ),
              ),
              _BottomActionsBar(
                statusBusy: _actionBusy,
                onMessage: () => _onMessage(d),
                onReject: d.isTerminalStatus
                    ? null
                    : () => _confirmAndUpdateStatus(context, 'rejected'),
                onHired: d.isTerminalStatus
                    ? null
                    : () => _confirmAndUpdateStatus(context, 'hired'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.detail});

  final ApplicantDetail detail;

  @override
  Widget build(BuildContext context) {
    final hasImage = detail.profileImageUrl != null &&
        detail.profileImageUrl!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ClipOval(
            child: hasImage
                ? Image.network(
                    detail.profileImageUrl!,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(detail.name),
                  )
                : _avatarFallback(detail.name),
          ),
          const SizedBox(height: 12),
          Text(
            detail.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (detail.location.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  detail.location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (detail.email != null && detail.email!.trim().isNotEmpty)
                Expanded(
                  child: _ContactChip(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    onTap: () => _openExternalUri('mailto:${detail.email}'),
                  ),
                ),
              if (detail.email != null &&
                  detail.email!.trim().isNotEmpty &&
                  detail.phone != null &&
                  detail.phone!.trim().isNotEmpty)
                const SizedBox(width: 10),
              if (detail.phone != null && detail.phone!.trim().isNotEmpty)
                Expanded(
                  child: _ContactChip(
                    icon: Icons.phone_outlined,
                    label: 'Call',
                    onTap: () {
                      final raw = detail.phone!.replaceAll(RegExp(r'[^\d+]'), '');
                      if (raw.isNotEmpty) {
                        _openExternalUri('tel:$raw');
                      }
                    },
                  ),
                ),
            ],
          ),
          if ((detail.email == null || detail.email!.trim().isEmpty) &&
              (detail.phone == null || detail.phone!.trim().isEmpty))
            Text(
              'No contact info on file',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Applied For',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail.appliedFor,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Received',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail.receivedOnLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (detail.appliedAgo != null)
                      Text(
                        detail.appliedAgo!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      width: 88,
      height: 88,
      color: AppColors.backgroundGrey,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brandPrimary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.brandPrimary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreyContentCard extends StatelessWidget {
  const _GreyContentCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.detail,
    required this.onView,
    required this.onDownload,
  });

  final ApplicantDetail detail;
  final VoidCallback onView;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final hasUrl =
        detail.resumeFileUrl != null && detail.resumeFileUrl!.trim().isNotEmpty;
    final name = detail.resumeFileName ?? 'Resume';
    final meta = detail.resumeFileSize != null
        ? '${detail.resumeFileSize} • PDF'
        : 'PDF';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: AppColors.brandPrimary, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  meta,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (hasUrl) ...[
            _RoundIconAction(
              icon: Icons.visibility_outlined,
              onTap: onView,
            ),
            const SizedBox(width: 8),
            _RoundIconAction(
              icon: Icons.download_outlined,
              onTap: onDownload,
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundIconAction extends StatelessWidget {
  const _RoundIconAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundGrey.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.detail});

  final ApplicantDetail detail;

  @override
  Widget build(BuildContext context) {
    final hired = detail.applicationStatus == 'hired';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hired
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            hired ? Icons.check_circle_outline : Icons.info_outline,
            color: hired ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hired
                  ? 'This applicant is marked as hired.'
                  : 'This application was not selected.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: hired ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionsBar extends StatelessWidget {
  const _BottomActionsBar({
    required this.statusBusy,
    required this.onMessage,
    required this.onReject,
    required this.onHired,
  });

  final bool statusBusy;
  final VoidCallback onMessage;
  final VoidCallback? onReject;
  final VoidCallback? onHired;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: AppColors.backgroundWhite,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                text: 'Message',
                onPressed: onMessage,
                icon: Icons.chat_bubble_outline,
                height: 48,
              ),
              if (onReject != null || onHired != null) ...[
                const SizedBox(height: 10),
                if (statusBusy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (onReject != null)
                        TextButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close, size: 20, color: AppColors.error),
                          label: const Text(
                            'Reject',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (onReject != null && onHired != null)
                        const SizedBox(width: 20),
                      if (onHired != null)
                        TextButton.icon(
                          onPressed: onHired,
                          icon: const Icon(Icons.check, size: 20, color: AppColors.success),
                          label: const Text(
                            'Mark as Hired',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
