import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/business_review.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../widgets/empty_state_widget.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/utils/relative_time_short.dart';

/// Up to two letters (e.g. "Yared Kassa" → "YK").
String _reviewAvatarInitials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  final w = parts[0];
  if (w.length >= 2) return w.substring(0, 2).toUpperCase();
  return w[0].toUpperCase();
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
      elevation: 2,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overview.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  final idx = i + 1;
                  final avg = overview.averageRating;
                  final IconData icon;
                  final Color color;
                  if (avg >= idx) {
                    icon = Icons.star;
                    color = AppColors.brandPrimary;
                  } else if (avg >= idx - 0.5) {
                    icon = Icons.star_half;
                    color = AppColors.brandPrimary;
                  } else {
                    icon = Icons.star_border;
                    color = AppColors.textTertiary;
                  }
                  return Icon(icon, size: 22, color: color);
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
    final initials = _reviewAvatarInitials(review.authorName);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      elevation: 2,
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
                        initials,
                        style: TextStyle(
                          fontSize: initials.length > 1 ? 11 : 14,
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
                      formatShortTimeAgo(review.createdAt),
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
              final filled = i < review.rating;
              return Icon(
                filled ? Icons.star : Icons.star_border,
                size: 18,
                color: filled
                    ? AppColors.brandPrimary
                    : AppColors.textTertiary,
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
                border: const Border(
                  left: BorderSide(color: AppColors.brandPrimary, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Response',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                      if (review.responseTimeAgo != null)
                        Text(
                          review.responseTimeAgo!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
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
