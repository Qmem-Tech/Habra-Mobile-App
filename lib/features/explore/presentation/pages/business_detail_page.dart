import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_share.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/repositories/businesses_repository.dart';
import '../bloc/businesses_cubit.dart';
import '../bloc/businesses_state.dart';
import '../bloc/reviews_cubit.dart';
import '../bloc/reviews_state.dart';
import '../widgets/business_card.dart';
import '../widgets/review_widget.dart';
import 'write_review_page.dart';
import 'map_page.dart';

class BusinessDetailPage extends StatelessWidget {
  final String businessId;

  const BusinessDetailPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<BusinessesCubit>()..loadBusinessDetail(businessId)),
        BlocProvider(create: (_) => di.sl<ReviewsCubit>()..loadReviews(businessId)),
      ],
      child: BlocListener<BusinessesCubit, BusinessesState>(
        listenWhen: (prev, curr) =>
            curr is BusinessDetailLoaded && prev is! BusinessDetailLoaded,
        listener: (context, state) {
          unawaited(
            di.sl<BusinessesRepository>().recordBusinessListingView(businessId),
          );
        },
        child: Scaffold(
          body: BlocBuilder<BusinessesCubit, BusinessesState>(
            builder: (context, state) {
              if (state is BusinessDetailLoading) {
                return const HabraCircularLoader(fullScreen: true);
              }

              if (state is BusinessDetailError) {
                return _buildErrorView(context, state.message);
              }

              if (state is BusinessDetailLoaded) {
                return _buildContent(context, state.business);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic business) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context, business),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(business),
              _buildActionButtons(context, business),
              if (business.currentDeals.isNotEmpty) _buildCurrentDeals(business),
              _buildAbout(business),
              _buildLocation(context, business),
              _buildPhotos(business),
              _buildReviews(context, business),
              if (business.similarBusinesses.isNotEmpty) _buildSimilarBusinesses(business),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic business) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Image.asset(
          business.imageUrls.isNotEmpty ? business.imageUrls.first : AppAssets.businessPlaceholder,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.backgroundGrey,
              child: const Icon(Icons.store, size: 64, color: AppColors.textSecondary),
            );
          },
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            final name = business.name as String? ?? 'Business';
            final addr = business.fullAddress as String? ?? '';
            shareText(
              addr.isNotEmpty ? '$name\n$addr' : name,
              subject: name,
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_border, color: Colors.white),
          onPressed: () {
            // saved_items table only supports event/deal; share is the supported “save” path for businesses today.
            final name = business.name as String? ?? 'Business';
            shareText('Saved via Habra: $name', subject: name);
          },
        ),
      ],
    );
  }

  Widget _buildHeader(dynamic business) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  business.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (business.isVerified)
                const Icon(Icons.verified, color: AppColors.brandPrimary, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  business.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${business.reviewCount} Reviews)',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${business.categories.map((c) => c.displayName).join(', ')} • ${business.priceRange ?? ''}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                business.isOpen ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: business.isOpen ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                business.isOpen
                    ? 'Open Now${business.closingTime != null ? ' • Closes ${business.closingTime}' : ''}'
                    : 'Closed${business.openingTime != null ? ' • Opens ${business.openingTime}' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: business.isOpen ? AppColors.success : AppColors.error,
                  fontWeight: business.isOpen ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, dynamic business) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.phone,
              label: 'Call',
              onTap: () => _launchDialer(context, business.phoneNumber as String?),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.directions,
              label: 'Route',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapPage(
                      businessId: business.id,
                      latitude: business.latitude,
                      longitude: business.longitude,
                      businessName: business.name,
                      businessAddress: business.fullAddress,
                      subtitle: business.categories.isNotEmpty
                          ? '${business.categories.first.displayName} • ${business.rating.toStringAsFixed(1)} (${business.reviewCount})'
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.brandPrimary.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.brandPrimary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentDeals(dynamic business) {
    if (business.currentDeals.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_offer, color: AppColors.brandSecondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Current Deals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...business.currentDeals.map((deal) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: AppColors.brandPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.discountText ?? deal.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (deal.description != null)
                          Text(
                            deal.description!,
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
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAbout(dynamic business) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            business.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation(BuildContext context, dynamic business) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.brandPrimary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  business.fullAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MapPage(
                    businessId: business.id,
                    latitude: business.latitude,
                    longitude: business.longitude,
                  ),
                ),
              );
            },
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.map,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotos(dynamic business) {
    if (business.photos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'View All >',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: business.photos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      business.photos[index],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: AppColors.backgroundGrey,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews(BuildContext context, dynamic business) {
    return BlocBuilder<ReviewsCubit, ReviewsState>(
      builder: (context, reviewsState) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reviews',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // View all reviews
                    },
                    child: const Text('View All >'),
                  ),
                ],
              ),
              if (reviewsState is ReviewsLoaded) ...[
                _buildRatingSummary(business, reviewsState.reviews),
                const SizedBox(height: 16),
                if (reviewsState.reviews.isNotEmpty)
                  ReviewWidget(review: reviewsState.reviews.first),
              ],
              const SizedBox(height: 16),
              AppButton(
                text: 'Write A Review',
                icon: Icons.edit,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WriteReviewPage(businessId: business.id, businessName: business.name),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingSummary(dynamic business, reviews) {
    final ratingCounts = List.generate(5, (index) {
      final star = 5 - index;
      return reviews.where((r) => r.rating == star).length;
    });

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              business.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  Icons.star,
                  size: 20,
                  color: index < business.rating.round()
                      ? Colors.amber
                      : AppColors.backgroundGrey,
                );
              }),
            ),
            Text(
              '${business.reviewCount} ratings',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: List.generate(5, (index) {
              final star = 5 - index;
              final count = ratingCounts[index];
              final total = reviews.length;
              final percentage = total > 0 ? count / total : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '$star',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: percentage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarBusinesses(dynamic business) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Similar Businesses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: business.similarBusinesses.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: BusinessCard(
                    business: business.similarBusinesses[index],
                    onTap: () {
                      // Navigate to business detail
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchDialer(BuildContext context, String? raw) async {
    if (raw == null || raw.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid phone number')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open phone dialer')),
      );
    }
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
