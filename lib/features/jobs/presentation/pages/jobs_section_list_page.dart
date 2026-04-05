import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/job_listing.dart';
import '../bloc/jobs_cubit.dart';
import '../widgets/recent_job_card.dart';
import 'job_detail_page.dart';

/// Full list for "View all" from Featured or Recent on the jobs home tab.
class JobsSectionListPage extends StatelessWidget {
  const JobsSectionListPage({
    super.key,
    required this.title,
    required this.jobs,
  });

  final String title;
  final List<JobListing> jobs;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<JobsCubit>();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: jobs.isEmpty
          ? Center(
              child: Text(
                'No jobs in this list yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final job = jobs[index];
                return RecentJobCard(
                  job: job,
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => JobDetailPage(jobId: job.id),
                      ),
                    );
                  },
                  onBookmark: () {
                    cubit.toggleBookmark(job.id, !job.isBookmarked);
                  },
                );
              },
            ),
    );
  }
}
