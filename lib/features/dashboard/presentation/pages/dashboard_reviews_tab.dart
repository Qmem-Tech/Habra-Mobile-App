import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/business_review.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../widgets/empty_state_widget.dart';
import '../../../../core/resources/app_assets.dart';

String _reviewAvatarInitial(String name) {
  if (name.isEmpty) return '?';
  return name[0].toUpperCase();
}

class DashboardReviewsTab extends StatelessWidget {
  const DashboardReviewsTab({
    super.key,
    this.overview,
    required this.reviews,
    required this.onRespond,
    this.onEditResponse,
  });

  final RatingOverview? overview;
  final List<BusinessReview> reviews;
  final void Function(BusinessReview review) onRespond;
  final void Function(BusinessReview review)? onEditResponse;

  @override
  Widget build(BuildContext context) {
    if (overview == null && reviews.isEmpty) {
      return EmptyStateWidget(
        illustrationPath: AppAssets.dashboardNoReviews,
        title: 'No reviews yet',
        description: 'When customers leave reviews, they\'ll show here. '
            'You can respond to build trust and show you care.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 8, AppResources.spacingM, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overview != null) ...[
            _RatingOverviewCard(overview: overview!),
            const SizedBox(height: 24),
          ],
          const Text(
            'Recent Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...reviews.map((r) => _ReviewCard(
                review: r,
                onRespond: () => onRespond(r),
                onEditResponse: r.hasResponse ? () => onEditResponse?.call(r) : null,
              )),
        ],
      ),
    );
  }
}

class _RatingOverviewCard extends StatelessWidget {
  const _RatingOverviewCard({required this.overview});

  final RatingOverview overview;

  @override
  Widget build(BuildContext context) {
    final total = overview.totalReviews;
    final dist = overview.distribution;
    final maxCount = dist.values.isEmpty ? 1 : dist.values.reduce((a, b) => a > b ? a : b);

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${overview.averageRating}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  final filled = (i + 1) <= overview.averageRating.round();
                  final half = (i + 1) - overview.averageRating == 0.5;
                  return Icon(
                    half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
                    size: 22,
                    color: AppColors.brandPrimary,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '$total reviews',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((stars) {
                final count = dist[stars] ?? 0;
                final width = maxCount > 0 ? (count / maxCount) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$stars',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: width.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: AppColors.backgroundGrey,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$count',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.onRespond,
    this.onEditResponse,
  });

  final BusinessReview review;
  final VoidCallback onRespond;
  final VoidCallback? onEditResponse;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.backgroundGrey,
                backgroundImage: review.authorImageUrl != null
                    ? NetworkImage(review.authorImageUrl!)
                    : null,
                child: review.authorImageUrl == null
                    ? Text(
                        _reviewAvatarInitial(review.authorName),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      review.timeAgo,
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating ? Icons.star : Icons.star_border,
                size: 18,
                color: AppColors.brandPrimary,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            review.text,
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
          ),
          if (review.hasResponse) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(color: AppColors.brandPrimary, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Your Response',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                      if (review.responseTimeAgo != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          review.responseTimeAgo!,
                          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.responseText!,
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                  if (onEditResponse != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onEditResponse,
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: AppColors.brandPrimary),
                          const SizedBox(width: 4),
                          const Text(
                            'Edit Response',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (!review.hasResponse) ...[
            const SizedBox(height: 12),
            AppButton(
              text: 'Respond',
              onPressed: onRespond,
              icon: Icons.reply,
              height: 40,
            ),
          ],
        ],
      ),
    );
  }
}
