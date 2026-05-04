import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_share.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../saved_items/domain/entities/saved_item.dart';
import '../../../saved_items/domain/usecases/save_item_usecase.dart';
import '../../../events/domain/entities/event_list_item.dart';
import '../../../events/domain/usecases/get_events_by_business_usecase.dart';
import '../../../events/presentation/pages/event_detail_page.dart';
import '../../../events/presentation/widgets/event_list_card.dart';
import '../../domain/entities/business_detail.dart';
import '../../domain/entities/review.dart';
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

  Widget _buildContent(BuildContext context, BusinessDetail business) {
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
              BusinessHostedEventsSection(businessId: business.id),
              _buildAbout(business),
              _buildLocation(context, business),
              _buildPhotos(business),
              _buildReviews(context, business),
              if (business.similarBusinesses.isNotEmpty) _buildSimilarBusinesses(context, business),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, BusinessDetail business) {
    final hero = business.imageUrls.isNotEmpty ? business.imageUrls.first : AppAssets.businessPlaceholder;
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: SizedBox.expand(
          child: _coverImage(hero),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () => _shareBusiness(context, business),
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_border, color: Colors.white),
          onPressed: () async {
            if (Supabase.instance.client.auth.currentUser == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sign in to save businesses')),
              );
              return;
            }
            final meta = _categoryAndPriceLine(business);
            final addr = business.fullAddress.trim();
            final subtitleParts = <String>[
              if (meta.isNotEmpty) meta,
              if (addr.isNotEmpty && addr != 'Address not available') addr,
            ];
            final subtitleStr =
                subtitleParts.isEmpty ? null : subtitleParts.join(' · ');
            final result = await di.sl<SaveItemUseCase>()(
              itemType: SavedItemType.business,
              referenceId: business.id,
              title: business.name.trim(),
              subtitle: subtitleStr,
              imageUrl: business.imageUrls.isNotEmpty
                  ? business.imageUrls.first
                  : null,
            );
            if (!context.mounted) return;
            result.fold(
              (f) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(f.message)),
              ),
              (_) => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Business saved to your list')),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader(BusinessDetail business) {
    final metaLine = _categoryAndPriceLine(business);
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
          if (metaLine.isNotEmpty) ...[
            Text(
              metaLine,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
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

  Widget _buildActionButtons(BuildContext context, BusinessDetail business) {
    final site = business.website?.trim();
    final hasSite = site != null && site.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.phone,
              label: 'Call',
              onTap: () => _launchDialer(context, business.phoneNumber),
            ),
          ),
          const SizedBox(width: 12),
          if (hasSite) ...[
            Expanded(
              child: _buildActionButton(
                icon: Icons.language,
                label: 'Website',
                onTap: () => _launchWebsite(context, site),
              ),
            ),
            const SizedBox(width: 12),
          ],
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

  Widget _buildCurrentDeals(BusinessDetail business) {
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
                        Text(
                          deal.description,
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

  Widget _buildAbout(BusinessDetail business) {
    final desc = business.description.trim();
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
            desc.isEmpty
                ? 'No description has been added for this business yet.'
                : desc,
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

  Widget _buildLocation(BuildContext context, BusinessDetail business) {
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
                    businessName: business.name,
                    businessAddress: business.fullAddress,
                    subtitle: business.categories.isNotEmpty
                        ? '${business.categories.first.displayName} • ${business.rating.toStringAsFixed(1)} (${business.reviewCount})'
                        : null,
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

  Widget _buildPhotos(BusinessDetail business) {
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
                    child: _galleryThumb(business.photos[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews(BuildContext context, BusinessDetail business) {
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

  Widget _buildRatingSummary(BusinessDetail business, List<Review> reviews) {
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

  Widget _buildSimilarBusinesses(BuildContext context, BusinessDetail business) {
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
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BusinessDetailPage(
                            businessId: business.similarBusinesses[index].id,
                          ),
                        ),
                      );
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

  static String _categoryAndPriceLine(BusinessDetail business) {
    final cats = business.categories.map((c) => c.displayName).join(', ');
    final price = business.priceRange?.trim() ?? '';
    final parts = <String>[
      if (cats.isNotEmpty) cats,
      if (price.isNotEmpty) price,
    ];
    return parts.join(' • ');
  }

  static bool _isHttpUrl(String url) {
    final l = url.toLowerCase().trim();
    return l.startsWith('http://') || l.startsWith('https://');
  }

  static Widget _coverImage(String url) {
    if (_isHttpUrl(url)) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _placeholderCover(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return ColoredBox(
            color: AppColors.backgroundGrey,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
      );
    }
    if (url.isNotEmpty) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _placeholderCover(),
      );
    }
    return _placeholderCover();
  }

  static Widget _placeholderCover() {
    return const ColoredBox(
      color: AppColors.backgroundGrey,
      child: Center(
        child: Icon(Icons.store, size: 64, color: AppColors.textSecondary),
      ),
    );
  }

  static Widget _galleryThumb(String url) {
    const w = 100.0;
    const h = 100.0;
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return Container(width: w, height: h, color: AppColors.backgroundGrey);
    }
    if (_isHttpUrl(trimmed)) {
      return Image.network(
        trimmed,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(width: w, height: h, color: AppColors.backgroundGrey),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: w,
            height: h,
            color: AppColors.backgroundGrey,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }
    return Image.asset(
      trimmed,
      width: w,
      height: h,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(width: w, height: h, color: AppColors.backgroundGrey),
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

  static Future<void> _launchWebsite(BuildContext context, String raw) async {
    var uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      uri = Uri.tryParse('https://$raw');
    }
    if (uri == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid website URL')),
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open website')),
      );
    }
  }

  static Future<void> _shareBusiness(
    BuildContext context,
    BusinessDetail business,
  ) async {
    final name = business.name.trim();
    final address = business.fullAddress.trim();
    final body = address.isNotEmpty ? '$name\n$address' : name;
    final text = '$body\n\nBusiness on Habra';
    try {
      await shareText(text, subject: name);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open share sheet')),
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

/// Upcoming events linked to this business listing (`events.business_id`).
class BusinessHostedEventsSection extends StatefulWidget {
  final String businessId;

  const BusinessHostedEventsSection({super.key, required this.businessId});

  @override
  State<BusinessHostedEventsSection> createState() =>
      _BusinessHostedEventsSectionState();
}

class _BusinessHostedEventsSectionState extends State<BusinessHostedEventsSection> {
  late final Future<Either<Failure, List<EventListItem>>> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = di.sl<GetEventsByBusinessUseCase>()(widget.businessId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, List<EventListItem>>>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();

        return data.fold(
          (_) => const SizedBox.shrink(),
          (events) {
            if (events.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.event_available, color: AppColors.brandPrimary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Events from this business',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...events.map(
                    (e) => EventListCard(
                      event: e,
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => EventDetailPage(eventId: e.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
