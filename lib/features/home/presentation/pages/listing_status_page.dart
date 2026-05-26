import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/navigation/business_owner_navigation_wrapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/listing_status_entity.dart';
import 'business_owner_wrapper_page.dart';

void _restartBusinessOwnerShell(BuildContext context) {
  final authState = context.read<AuthCubit>().state;
  if (authState is AuthAuthenticated) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => BusinessOwnerWrapperPage(user: authState.user),
      ),
      (route) => false,
    );
    return;
  }
  Navigator.of(context).popUntil((route) => route.isFirst);
}

/// Listing Status: pending (review) or live + verified with business card.
class ListingStatusPage extends StatelessWidget {
  const ListingStatusPage({
    super.key,
    this.isVerified = false,
    this.businessId = '',
    this.businessName,
    this.cityName,
    this.imageUrl = '',
    this.locationText,
    this.refreshOwnerShellOnContinue = false,
  });

  final bool isVerified;
  final String businessId;
  final String? businessName;
  /// City from registration (preferred for copy and card).
  final String? cityName;
  final String imageUrl;
  /// Full address line when available (e.g. street + city).
  final String? locationText;
  /// After first listing from the empty-owner shell, restart wrapper so Home loads the new business.
  final bool refreshOwnerShellOnContinue;

  ListingStatusEntity _listingEntity(BuildContext context) {
    return ListingStatusEntity(
      businessId: businessId,
      businessName: businessName ?? 'Your business',
      cityName: cityName,
      locationText: locationText,
      imageUrl: imageUrl,
      status: isVerified ? ListingStatusType.verified : ListingStatusType.pending,
      isNewBusiness: businessId.isNotEmpty,
    );
  }

  String _primaryLocationLine(ListingStatusEntity entity) {
    final c = entity.cityName?.trim();
    if (c != null && c.isNotEmpty && c.toLowerCase() != 'unknown') {
      return c;
    }
    final loc = entity.locationText?.trim();
    if (loc != null && loc.isNotEmpty) {
      final parts = loc.split(',');
      if (parts.length >= 2) {
        final last = parts.last.trim();
        if (last.isNotEmpty) return last;
      }
      return loc;
    }
    return 'Location not set';
  }

  String _pendingBodyCopy(ListingStatusEntity entity) {
    final name = entity.businessName;
    final city = entity.cityName?.trim();
    final hasCity =
        city != null && city.isNotEmpty && city.toLowerCase() != 'unknown';
    if (hasCity) {
      return '$name in $city is currently under review and not yet visible '
          'to the community.';
    }
    return '$name is currently under review and not yet visible to the community.';
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
          onPressed: () {
            if (refreshOwnerShellOnContinue) {
              _restartBusinessOwnerShell(context);
            } else {
              Navigator.of(context).pop();
            }
          },
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
        child: isVerified
            ? _buildVerifiedBody(context, entity)
            : _buildPendingBody(context, entity),
      ),
      bottomNavigationBar: isVerified
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppResources.spacingL,
                8,
                AppResources.spacingL,
                AppResources.spacingM,
              ),
              child: AppButton(
                text: 'Go To Homepage',
                onPressed: () {
                  if (refreshOwnerShellOnContinue) {
                    _restartBusinessOwnerShell(context);
                  } else {
                    BusinessOwnerNavigationWrapper.popCurrentRouteAndOpenHome(
                      context,
                    );
                  }
                },
              ),
            ),
    );
  }

  Widget _buildPendingBody(BuildContext context, ListingStatusEntity entity) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingL),
      child: Column(
        children: [
          const SizedBox(height: 8),
          SvgPicture.asset(
            AppAssets.pendingStatusSvg,
            width: 150,
            height: 158,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 28),
          const Text(
            'Your Business Is Pending!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _pendingBodyCopy(entity),
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildBusinessCard(entity),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVerifiedBody(BuildContext context, ListingStatusEntity entity) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingL),
      child: Column(
        children: [
          const SizedBox(height: 24),
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
          const SizedBox(height: 28),
          _buildBusinessCard(entity),
          const SizedBox(height: 32),
          AppButton(
            text: 'Preview Listing',
            onPressed: () {
              if (refreshOwnerShellOnContinue) {
                _restartBusinessOwnerShell(context);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildLocationBlock(ListingStatusEntity entity) {
    final primary = _primaryLocationLine(entity);
    final extra = entity.locationText?.trim();
    final showExtra = extra != null &&
        extra.isNotEmpty &&
        extra.toLowerCase() != primary.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primary,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (showExtra) ...[
                    const SizedBox(height: 4),
                    Text(
                      extra,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 10),
                    _buildLocationBlock(entity),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
