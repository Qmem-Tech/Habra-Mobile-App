import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/resources/app_assets.dart';
import '../../domain/entities/my_review.dart';
import '../bloc/my_reviews_cubit.dart';
import '../bloc/my_reviews_state.dart';
import '../../../../injection/injection_container.dart' as di;

class MyReviewsPage extends StatelessWidget {
  const MyReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<MyReviewsCubit>()..loadMyReviews(),
      child: const _MyReviewsView(),
    );
  }
}

class _MyReviewsView extends StatelessWidget {
  const _MyReviewsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Reviews'),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocBuilder<MyReviewsCubit, MyReviewsState>(
        builder: (context, state) {
          if (state is MyReviewsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MyReviewsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppResources.spacingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: AppResources.spacingM),
                    AppButton(
                      text: 'Retry',
                      onPressed: () =>
                          context.read<MyReviewsCubit>().loadMyReviews(),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is MyReviewsLoaded && state.reviews.isEmpty) {
            return EmptyStateWidget(
              illustrationPath: AppAssets.myReviewsEmpty,
              title: 'No review yet',
              message: 'Be the first to share your experience.',
              buttonLabel: 'Explore businesses',
              onButtonTap: () => Navigator.pop(context),
            );
          }
          if (state is MyReviewsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<MyReviewsCubit>().loadMyReviews();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(AppResources.spacingM),
                itemCount: state.reviews.length,
                itemBuilder: (context, index) {
                  return _ReviewCard(review: state.reviews[index]);
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

class _ReviewCard extends StatelessWidget {
  final MyReview review;

  const _ReviewCard({required this.review});

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
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
              ClipRRect(
                borderRadius: BorderRadius.circular(AppResources.radiusM),
                child: review.businessImageUrl != null &&
                        review.businessImageUrl!.isNotEmpty
                    ? Image.network(
                        review.businessImageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: AppResources.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.businessName,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          size: 18,
                          color: AppColors.brandSecondary,
                        ),
                      ),
                    ),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppResources.spacingS),
          Text(
            review.comment,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: AppResources.spacingM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditDialog(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandPrimary,
                    side: const BorderSide(color: AppColors.brandPrimary),
                  ),
                ),
              ),
              const SizedBox(width: AppResources.spacingS),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.backgroundGrey.withValues(alpha: 0.5),
      child: const Icon(Icons.store, color: AppColors.textTertiary),
    );
  }

  void _showEditDialog(BuildContext context) {
    final ratingController = TextEditingController(text: review.rating.toString());
    final commentController = TextEditingController(text: review.comment);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Review'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rating (1-5)'),
              TextField(
                controller: ratingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '1-5'),
              ),
              const SizedBox(height: 16),
              const Text('Review'),
              TextField(
                controller: commentController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Your review'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final rating = int.tryParse(ratingController.text);
              final comment = commentController.text.trim();
              if (rating == null || rating < 1 || rating > 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rating must be 1-5')),
                );
                return;
              }
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              final success = await context.read<MyReviewsCubit>().updateReview(
                    review.id,
                    rating: rating,
                    comment: comment.isEmpty ? null : comment,
                  );
              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Review updated'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to update review'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text(
          'Are you sure you want to delete this review? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              final success =
                  await context.read<MyReviewsCubit>().deleteReview(review.id);
              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Review deleted'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete review'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
