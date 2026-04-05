import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../../dashboard/presentation/pages/edit_business_page.dart';
import '../../domain/entities/business_presence.dart';
import 'owner_business_group_card.dart';

/// Single-line address for a listing (street + city/state).
String ownerBranchAddressLine(BusinessPresence p) {
  final street = p.locationName?.trim();
  final city = p.city?.trim();
  final state = p.state?.trim();
  final parts = <String>[
    if (street != null && street.isNotEmpty) street,
    if (city != null && city.isNotEmpty) city,
    if (state != null && state.isNotEmpty) state,
  ];
  if (parts.isEmpty) return 'Address not set';
  return parts.join(', ');
}

Color _ratingColor(double? r) {
  if (r == null || r <= 0) return AppColors.textSecondary;
  if (r >= 4.5) return AppColors.success;
  if (r >= 4.0) return AppColors.brandPrimary;
  return AppColors.textSecondary;
}

/// Branch / location row matching the owner "My Locations" mock (card, stats, Edit + View).
class OwnerLocationBranchCard extends StatelessWidget {
  const OwnerLocationBranchCard({
    super.key,
    required this.presence,
    required this.onView,
    /// When non-null, overrides [BusinessPresence.monthlyProfileViews] for display.
    this.monthlyViews,
  });

  final BusinessPresence presence;
  final VoidCallback onView;
  final int? monthlyViews;

  Future<void> _openEdit(BuildContext context) async {
    final cubit = context.read<DashboardCubit>();
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => BlocProvider<DashboardCubit>.value(
          value: cubit,
          child: EditBusinessPage(business: presence),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rating = presence.rating;
    final ratingText = formatOwnerAvgRatingDisplay(rating);
    final viewsText = formatOwnerMonthlyViewsDisplay(
      monthlyViews ?? presence.monthlyProfileViews,
    );
    final phone = presence.phone?.trim();
    final label = presence.locationLabel?.trim();
    final title = (label != null && label.isNotEmpty)
        ? label
        : (presence.name.trim().isNotEmpty ? presence.name : 'Listing');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOwnerBusinessCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ratingText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _ratingColor(rating),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.star_rounded,
                    size: 20,
                    color: _ratingColor(rating),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ownerBranchAddressLine(presence),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 18, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    phone,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                viewsText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _openEdit(context),
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.textSecondary,
                tooltip: 'Edit',
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: onView,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                    ),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
