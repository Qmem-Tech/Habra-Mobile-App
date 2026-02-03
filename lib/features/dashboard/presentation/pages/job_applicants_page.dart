import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../domain/entities/job_applicant.dart';
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';
import 'applicant_details_page.dart';

class JobApplicantsPage extends StatefulWidget {
  const JobApplicantsPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.jobSubtitle,
  });

  final String jobId;
  final String jobTitle;
  final String jobSubtitle;

  @override
  State<JobApplicantsPage> createState() => _JobApplicantsPageState();
}

class _JobApplicantsPageState extends State<JobApplicantsPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadApplicants(
          widget.jobId,
          widget.jobTitle,
          widget.jobSubtitle,
        );
  }

  void _goBack(BuildContext context) {
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    if (homeState is BusinessOwnerHomeLoaded &&
        homeState.selectedPresence != null &&
        homeState.selectedPresence!.id != 'all') {
      context.read<DashboardCubit>().loadDashboard(homeState.selectedPresence!.id);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _JobApplicantsView(
      jobId: widget.jobId,
      jobTitle: widget.jobTitle,
      jobSubtitle: widget.jobSubtitle,
      onBack: () => _goBack(context),
    );
  }
}

class _JobApplicantsView extends StatefulWidget {
  const _JobApplicantsView({
    required this.jobId,
    required this.jobTitle,
    required this.jobSubtitle,
    required this.onBack,
  });

  final String jobId;
  final String jobTitle;
  final String jobSubtitle;
  final VoidCallback onBack;

  @override
  State<_JobApplicantsView> createState() => _JobApplicantsViewState();
}

class _JobApplicantsViewState extends State<_JobApplicantsView> {
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.jobTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.jobSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is ApplicantsLoading) {
            return const HabraCircularLoader(fullScreen: true);
          }
          if (state is! ApplicantsLoaded) {
            return const Center(child: Text('No data'));
          }
          final filter = _filterIndex == 0 ? null : (_filterIndex == 1 ? ApplicantStatus.newApplicant : ApplicantStatus.reviewed);
          final allCount = state.applicants.length;
          final newCount = state.applicants.where((a) => a.status == ApplicantStatus.newApplicant).length;

          List<JobApplicant> list = state.applicants;
          if (filter == ApplicantStatus.newApplicant) {
            list = list.where((a) => a.status == ApplicantStatus.newApplicant).toList();
          } else if (filter == ApplicantStatus.reviewed) {
            list = list.where((a) => a.status == ApplicantStatus.reviewed).toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All $allCount',
                      selected: _filterIndex == 0,
                      onTap: () => setState(() => _filterIndex = 0),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'New $newCount',
                      selected: _filterIndex == 1,
                      onTap: () => setState(() => _filterIndex = 1),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Reviewed',
                      selected: _filterIndex == 2,
                      onTap: () => setState(() => _filterIndex = 2),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (filter != ApplicantStatus.reviewed) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'New Applicants',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Mark all read', style: TextStyle(color: AppColors.brandPrimary)),
                          ),
                        ],
                      ),
                      ...list.where((a) => a.status == ApplicantStatus.newApplicant).map(                          (a) => _ApplicantCard(
                            applicant: a,
                            onViewFull: () => _openApplicantDetail(context, a),
                            onMessage: () {},
                          )),
                    ],
                    if (list.any((a) => a.status == ApplicantStatus.reviewed)) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recently Reviewed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View all', style: TextStyle(color: AppColors.brandPrimary)),
                          ),
                        ],
                      ),
                      ...state.applicants.where((a) => a.status == ApplicantStatus.reviewed).map((a) => _ApplicantCard(
                            applicant: a,
                            onViewFull: () => _openApplicantDetail(context, a),
                            onMessage: () {},
                            isReviewed: true,
                          )),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openApplicantDetail(BuildContext context, JobApplicant applicant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<DashboardCubit>(),
          child: ApplicantDetailsPage(
            applicantId: applicant.id,
            jobId: widget.jobId,
            applicantName: applicant.name,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandPrimary : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({
    required this.applicant,
    required this.onViewFull,
    required this.onMessage,
    this.isReviewed = false,
  });

  final JobApplicant applicant;
  final VoidCallback onViewFull;
  final VoidCallback onMessage;
  final bool isReviewed;

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
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.backgroundGrey,
                child: Icon(Icons.person, color: AppColors.textTertiary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicant.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${applicant.location} • ${applicant.timeAgo}',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    if (applicant.bioSnippet != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          applicant.bioSnippet!,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (isReviewed && applicant.statusLabel != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          applicant.statusLabel!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppOutlinedButton(
                  text: 'View Full',
                  onPressed: onViewFull,
                  height: 40,
                  textColor: AppColors.textPrimary,
                  borderColor: AppColors.backgroundGrey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  text: 'Message',
                  onPressed: onMessage,
                  icon: Icons.message_outlined,
                  height: 40,
                ),
              ),
            ],
          ),
          if (isReviewed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onViewFull,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('See Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
