import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../bloc/reviews_cubit.dart';
import '../bloc/reviews_state.dart';
import '../widgets/review_widget.dart';

/// Full list of reviews for a business. Reached from the "View All" link
/// on the business detail page.
class BusinessReviewsPage extends StatelessWidget {
  const BusinessReviewsPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReviewsCubit>(
      create: (_) => di.sl<ReviewsCubit>()..loadReviews(businessId),
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          title: Text(
            businessName.isEmpty ? 'Reviews' : '$businessName • Reviews',
          ),
          backgroundColor: AppColors.backgroundWhite,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: BlocBuilder<ReviewsCubit, ReviewsState>(
          builder: (context, state) {
            if (state is ReviewsLoading || state is ReviewsInitial) {
              return const HabraCircularLoader(fullScreen: true);
            }
            if (state is ReviewsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () =>
                            context.read<ReviewsCubit>().loadReviews(businessId),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is ReviewsLoaded) {
              final reviews = state.reviews;
              if (reviews.isEmpty) {
                return Center(
                  child: Text(
                    'No reviews yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<ReviewsCubit>().loadReviews(businessId),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    return ReviewWidget(review: reviews[index]);
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
