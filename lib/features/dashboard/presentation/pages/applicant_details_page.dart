import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../domain/entities/applicant_detail.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';

class ApplicantDetailsPage extends StatelessWidget {
  const ApplicantDetailsPage({
    super.key,
    required this.applicantId,
    required this.jobId,
    required this.applicantName,
  });

  final String applicantId;
  final String jobId;
  final String applicantName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<DashboardCubit>(),
      child: _ApplicantDetailsBody(
        applicantId: applicantId,
        jobId: jobId,
        applicantName: applicantName,
      ),
    );
  }
}

class _ApplicantDetailsBody extends StatefulWidget {
  const _ApplicantDetailsBody({
    required this.applicantId,
    required this.jobId,
    required this.applicantName,
  });

  final String applicantId;
  final String jobId;
  final String applicantName;

  @override
  State<_ApplicantDetailsBody> createState() => _ApplicantDetailsBodyState();
}

class _ApplicantDetailsBodyState extends State<_ApplicantDetailsBody> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadApplicantDetail(widget.applicantId, widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<DashboardCubit>().clearApplicantDetail();
            Navigator.pop(context);
          },
        ),
        title: const Text('Applicant Details'),
        centerTitle: true,
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is ApplicantDetailLoading) {
            return const HabraCircularLoader(fullScreen: true);
          }
          if (state is ApplicantDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  AppButton(text: 'Back', onPressed: () => Navigator.pop(context)),
                ],
              ),
            );
          }
          if (state is! ApplicantDetailLoaded) {
            return const Center(child: Text('No data'));
          }
          final d = state.detail;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppResources.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.backgroundGrey,
                        child: Text(
                          d.name.isNotEmpty ? d.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 36, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        d.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(d.location, style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppButton(text: 'Email', onPressed: () {}, icon: Icons.email_outlined, width: 100),
                          const SizedBox(width: 12),
                          AppButton(text: 'Call', onPressed: () {}, icon: Icons.call_outlined, width: 100),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text('Applied For', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text(d.appliedFor, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Column(
                            children: [
                              Text('Received', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text(d.receivedDate, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Cover Letter', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(d.coverLetter, style: const TextStyle(fontSize: 14, height: 1.5)),
                const SizedBox(height: 24),
                const Text('Experience', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...d.experience.map((ApplicantExperience e) => AppCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${e.company} • ${e.employmentType}'),
                          Text('${e.period} • ${e.duration}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                const Text('Resume', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                if (d.resumeFileName != null)
                  AppCard(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(Icons.description, color: AppColors.brandPrimary),
                      title: Text(d.resumeFileName!),
                      subtitle: d.resumeFileSize != null ? Text('${d.resumeFileSize} • PDF') : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.visibility_outlined), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.download_outlined), onPressed: () {}),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                AppButton(text: 'Message', onPressed: () {}, icon: Icons.message_outlined),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                      label: const Text('Reject', style: TextStyle(color: AppColors.error)),
                    ),
                    const SizedBox(width: 24),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.check, size: 18, color: AppColors.success),
                      label: const Text('Mark as Hired', style: TextStyle(color: AppColors.success)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
