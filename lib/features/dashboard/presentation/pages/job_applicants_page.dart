import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../domain/entities/job_applicant.dart';
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';
import 'applicant_details_page.dart';

/// Teal accent for "New" count badge (matches product mock).
const Color _kNewBadgeTeal = Color(0xFF2A9D8F);

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
  /// 0 = All, 1 = New, 2 = Reviewed
  int _tabIndex = 0;
  bool _markAllBusy = false;

  Future<void> _onMarkAllRead(BuildContext context) async {
    setState(() => _markAllBusy = true);
    final ok =
        await context.read<DashboardCubit>().markAllApplicantsReadForJob();
    if (mounted) setState(() => _markAllBusy = false);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'All new applicants marked as read.'
              : 'Could not update applicants. Try again.',
        ),
      ),
    );
  }

  void _openApplicantDetail(BuildContext context, JobApplicant applicant) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<DashboardCubit>(),
          child: ApplicantDetailsPage(
            applicantId: applicant.id,
            jobId: widget.jobId,
            applicantName: applicant.name,
            jobTitle: widget.jobTitle,
            jobSubtitle: widget.jobSubtitle,
          ),
        ),
      ),
    );
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
          onPressed: widget.onBack,
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.jobTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.jobSubtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
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

          final applicants = state.applicants;
          final pending =
              applicants.where((a) => a.isPending).toList(growable: false);
          final processed =
              applicants.where((a) => !a.isPending).toList(growable: false);
          final allCount = applicants.length;
          final newCount = pending.length;
          final reviewedCount = processed.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _ApplicantsSegmentedBar(
                  allCount: allCount,
                  newCount: newCount,
                  reviewedCount: reviewedCount,
                  selectedIndex: _tabIndex,
                  onSelect: (i) => setState(() => _tabIndex = i),
                ),
              ),
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                  children: [
                    if (_tabIndex != 2) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'New Applicants',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: pending.isEmpty || _markAllBusy
                                ? null
                                : () => _onMarkAllRead(context),
                            child: _markAllBusy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.brandPrimary,
                                    ),
                                  )
                                : const Text(
                                    'Mark all read',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.brandPrimary,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (pending.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            _tabIndex == 1
                                ? 'No new applicants.'
                                : 'No new applicants right now.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else
                        ...pending.map(
                          (a) => _NewApplicantCard(
                            applicant: a,
                            onViewFull: () =>
                                _openApplicantDetail(context, a),
                            onMessage: () =>
                                _openApplicantDetail(context, a),
                          ),
                        ),
                    ],
                    if (_tabIndex != 2 && processed.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recently Reviewed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _tabIndex = 2),
                            child: const Text(
                              'View all',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...processed.map(
                        (a) => _ReviewedApplicantCard(
                          applicant: a,
                          onSeeDetails: () =>
                              _openApplicantDetail(context, a),
                        ),
                      ),
                    ],
                    if (_tabIndex == 2) ...[
                      if (processed.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No reviewed applicants yet.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        ...processed.map(
                          (a) => _ReviewedApplicantCard(
                            applicant: a,
                            onSeeDetails: () =>
                                _openApplicantDetail(context, a),
                          ),
                        ),
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
}

class _ApplicantsSegmentedBar extends StatelessWidget {
  const _ApplicantsSegmentedBar({
    required this.allCount,
    required this.newCount,
    required this.reviewedCount,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int allCount;
  final int newCount;
  final int reviewedCount;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentCell(
              selected: selectedIndex == 0,
              onTap: () => onSelect(0),
              child: Text(
                'All ($allCount)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selectedIndex == 0
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: _SegmentCell(
              selected: selectedIndex == 1,
              onTap: () => onSelect(1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'New ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selectedIndex == 1
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selectedIndex == 1
                          ? _kNewBadgeTeal
                          : _kNewBadgeTeal.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$newCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selectedIndex == 1
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _SegmentCell(
              selected: selectedIndex == 2,
              onTap: () => onSelect(2),
              child: Text(
                reviewedCount > 0
                    ? 'Reviewed ($reviewedCount)'
                    : 'Reviewed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selectedIndex == 2
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentCell extends StatelessWidget {
  const _SegmentCell({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.backgroundWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ApplicantAvatar extends StatelessWidget {
  const _ApplicantAvatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return ClipOval(
      child: hasUrl
          ? Image.network(
              url!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.backgroundGrey,
      child: const Icon(
        Icons.person,
        color: AppColors.textTertiary,
        size: 28,
      ),
    );
  }
}

class _NewApplicantCard extends StatelessWidget {
  const _NewApplicantCard({
    required this.applicant,
    required this.onViewFull,
    required this.onMessage,
  });

  final JobApplicant applicant;
  final VoidCallback onViewFull;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final loc = applicant.location.isEmpty
        ? applicant.timeAgo
        : '${applicant.location} • ${applicant.timeAgo}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.backgroundGrey.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
              _ApplicantAvatar(url: applicant.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicant.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (applicant.bioSnippet != null &&
                        applicant.bioSnippet!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          applicant.bioSnippet!,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewFull,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.backgroundGrey),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'View Full',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  text: 'Message',
                  onPressed: onMessage,
                  icon: Icons.chat_bubble_outline,
                  height: 44,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewedApplicantCard extends StatelessWidget {
  const _ReviewedApplicantCard({
    required this.applicant,
    required this.onSeeDetails,
  });

  final JobApplicant applicant;
  final VoidCallback onSeeDetails;

  @override
  Widget build(BuildContext context) {
    final loc = applicant.location.isEmpty
        ? applicant.timeAgo
        : '${applicant.location} • ${applicant.timeAgo}';
    final label = applicant.statusLabel ?? 'Reviewed';
    final orangeStyle = applicant.rawStatus == 'shortlisted';
    final badgeFg =
        orangeStyle ? AppColors.warning : AppColors.brandPrimary;
    final badgeBg = badgeFg.withValues(alpha: 0.14);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.backgroundGrey.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
              _ApplicantAvatar(url: applicant.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicant.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: badgeFg,
                            ),
                          ),
                        ),
                        if (applicant.statusTimeAgo != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            applicant.statusTimeAgo!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onSeeDetails,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.only(top: 8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See Details',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
