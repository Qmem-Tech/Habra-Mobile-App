import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../bloc/jobs_cubit.dart';
import '../bloc/jobs_state.dart';
import 'apply_for_job_page.dart';

class JobDetailPage extends StatelessWidget {
  final String jobId;

  const JobDetailPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = di.sl<JobsCubit>();
        cubit.loadJobDetail(jobId);
        return cubit;
      },
      child: Scaffold(
        body: BlocBuilder<JobsCubit, JobsState>(
          builder: (context, state) {
            if (state is JobDetailLoading) {
              return const HabraCircularLoader(fullScreen: true);
            }

            if (state is JobDetailError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            if (state is JobDetailLoaded) {
              final job = state.jobDetail;
              return CustomScrollView(
                slivers: [
                  _buildAppBar(context, job),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCompanyCard(job),
                          const SizedBox(height: 16),
                          _buildJobAttributes(job),
                          const SizedBox(height: 24),
                          _buildJobDescription(job),
                          const SizedBox(height: 24),
                          _buildRequirements(job),
                          const SizedBox(height: 24),
                          _buildBenefits(job),
                          const SizedBox(height: 24),
                          _buildLocation(job),
                          const SizedBox(height: 100), // Space for button
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
        bottomNavigationBar: BlocBuilder<JobsCubit, JobsState>(
          builder: (context, state) {
            if (state is JobDetailLoaded) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ApplyForJobPage(
                              jobId: jobId,
                              jobTitle: state.jobDetail.title,
                              companyName: state.jobDetail.companyName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Apply Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, job) {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        job.title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // TODO: Implement share
          },
        ),
        BlocBuilder<JobsCubit, JobsState>(
          builder: (context, state) {
            // TODO: track bookmark from cubit and toggle on pressed
            return IconButton(
              icon: const Icon(Icons.bookmark_border),
              color: AppColors.textPrimary,
              onPressed: () {
                // TODO: Toggle bookmark
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompanyCard(job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: job.companyLogoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      job.companyLogoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.business,
                          color: AppColors.textSecondary,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.business,
                    color: AppColors.textSecondary,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.companyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (job.companyRating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.brandSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${job.companyRating}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (job.location != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    job.location!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobAttributes(job) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildAttributeCard(
          icon: Icons.account_balance_wallet,
          label: 'Salary',
          value: job.salary ?? 'Not specified',
        ),
        _buildAttributeCard(
          icon: Icons.work,
          label: 'Type',
          value: job.jobType,
        ),
        _buildAttributeCard(
          icon: Icons.location_on,
          label: 'Location',
          value: job.location ?? 'Not specified',
        ),
        _buildAttributeCard(
          icon: Icons.access_time,
          label: 'Posted',
          value: job.postedDate != null
              ? '${DateTime.now().difference(job.postedDate!).inDays} days ago'
              : 'Recently',
        ),
      ],
    );
  }

  Widget _buildAttributeCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.brandPrimary, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildJobDescription(job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          job.description ?? 'No description available.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirements(job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requirements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...job.requirements.map((req) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.brandPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      req,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildBenefits(job) {
    if (job.benefits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Benefits',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: job.benefits.map((benefit) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brandPrimaryLight.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                benefit,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocation(job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Locations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  job.location ?? 'Location not specified',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
