import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/listing_status_entity.dart';

/// Listing Status: shows Verification Pending or Live and Verified with business card.
class ListingStatusPage extends StatelessWidget {
  const ListingStatusPage({super.key, this.isVerified = false});

  final bool isVerified;

  ListingStatusEntity _listingEntity(BuildContext context) {
    return ListingStatusEntity(
      businessId: '',
      businessName: 'Your business',
      locationText: null,
      imageUrl: '',
      status: isVerified ? ListingStatusType.verified : ListingStatusType.pending,
      isNewBusiness: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entity = _listingEntity(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Listing Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingL),
          child: Column(
            children: [
              const SizedBox(height: 24),
              if (isVerified) ...[
                Image.asset(
                  AppAssets.businessOwnerVerifiedBadge,
                  width: 80,
                  height: 80,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.brandSecondary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 56,
                      color: AppColors.brandSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your listing is live and verified',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Visible to everyone in the community',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.brandSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Verification Pending',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              _buildBusinessCard(entity),
              if (!isVerified) ...[
                const SizedBox(height: 28),
                const Text(
                  'Listing is visible, but...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your listing is currently live but unverified. Verify your business to gain trust and unlock premium features like analytics and promoted posts.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Need help? Contact Support',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (isVerified) ...[
                const SizedBox(height: 32),
                AppButton(
                  text: 'Preview Listing',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessCard(ListingStatusEntity entity) {
    return Container(
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entity.isNewBusiness)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'New Business',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.businessName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          entity.locationText ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppResources.radiusM),
                child: Image.network(
                  entity.imageUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: AppColors.backgroundGrey,
                    child: Image.asset(
                      AppAssets.businessPlaceholder,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.store),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
