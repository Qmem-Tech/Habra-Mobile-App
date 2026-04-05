import 'package:flutter/material.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/business_presence.dart';

/// Pending listing badge (light orange) — My Businesses design.
const Color kOwnerBusinessPendingBadgeBg = Color(0xFFFFE8D6);
const Color kOwnerBusinessPendingBadgeFg = Color(0xFFB85C1A);

/// Card border for owner business list cards.
const Color kOwnerBusinessCardBorder = Color(0xFFE8E8E8);

/// Monthly views for display (null/negative → 0). Uses k-style compacting from 1000+.
String formatOwnerMonthlyViewsDisplay(int? views) {
  final v = views ?? 0;
  if (v <= 0) return '0';
  if (v < 1000) return '$v';
  if (v < 1000000) {
    final x = v / 1000.0;
    final whole = x == x.roundToDouble();
    final s = x >= 10
        ? x.toStringAsFixed(0)
        : (whole ? x.toStringAsFixed(0) : x.toStringAsFixed(1));
    return '${s}k';
  }
  final x = v / 1000000.0;
  final s = x >= 10 ? x.toStringAsFixed(0) : x.toStringAsFixed(1);
  return '${s}M';
}

/// One decimal; no usable average → `0.0`.
String formatOwnerAvgRatingDisplay(double? average) {
  if (average == null || average <= 0) return '0.0';
  return average.toStringAsFixed(1);
}

/// Bottom sheet to pick a location within a business group.
Future<void> showOwnerBusinessLocationsSheet({
  required BuildContext context,
  required List<BusinessPresence> locations,
  required void Function(String presenceId) onPresenceSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.backgroundWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppResources.radiusL)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppResources.spacingM,
                  AppResources.spacingM,
                  AppResources.spacingM,
                  AppResources.spacingS,
                ),
                child: Text(
                  'Locations',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              const Divider(height: 1),
              ...locations.map(
                (p) => ListTile(
                  title: Text(
                    p.locationName?.trim().isNotEmpty == true
                        ? p.locationName!.trim()
                        : p.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: p.city != null && p.city!.trim().isNotEmpty
                      ? Text(p.city!.trim())
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onPresenceSelected(p.id);
                  },
                ),
              ),
              const SizedBox(height: AppResources.spacingS),
            ],
          ),
        ),
      );
    },
  );
}

/// Full-width primary CTA: "Add New Business" (or [buttonLabel]) + circled plus.
class OwnerAddNewBusinessCtaButton extends StatelessWidget {
  const OwnerAddNewBusinessCtaButton({
    super.key,
    required this.onPressed,
    this.buttonLabel = 'Add New Business',
    this.promptText,
    this.promptIcon = Icons.storefront_outlined,
  });

  final VoidCallback onPressed;
  final String buttonLabel;
  /// When set, shows above the button (e.g. "Have another branch?").
  final String? promptText;
  final IconData promptIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (promptText != null) ...[
          Center(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(promptIcon, color: AppColors.textTertiary, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  promptText!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
        SizedBox(
          width: double.infinity,
          height: AppResources.buttonHeightL,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppResources.radiusM),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textOnPrimary, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.add, size: 18, color: AppColors.textOnPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One grouped business card: logo, badges, stats, View Locations / Manage.
class OwnerBusinessGroupCard extends StatelessWidget {
  const OwnerBusinessGroupCard({
    super.key,
    required this.groupKey,
    required this.locations,
    this.currentPresenceId,
    required this.onPresenceSelected,
    this.monthlyViews,
  });

  final String groupKey;
  final List<BusinessPresence> locations;
  final String? currentPresenceId;
  final void Function(String presenceId) onPresenceSelected;

  /// Last-30-day profile views for this card (e.g. one business or summed locations). Null → show `0`.
  final int? monthlyViews;

  @override
  Widget build(BuildContext context) {
    final list = List<BusinessPresence>.from(locations);
    final primary = primaryPresenceInGroup(list, currentPresenceId);
    final logoUrl = primary.logoUrl?.isNotEmpty == true ? primary.logoUrl! : primary.imageUrl;
    final categoryLabel = primary.category;
    final locationSubtitle = locationSummaryLine(list);
    final avgRating = averageRating(list);
    final ratingLabel = formatOwnerAvgRatingDisplay(avgRating);
    final viewsLabel = formatOwnerMonthlyViewsDisplay(monthlyViews);
    final showPending = list.any((p) => p.isPendingApproval);
    final showVerified = list.any((p) => p.isVerified) && !showPending;

    return Container(
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        border: Border.all(color: kOwnerBusinessCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OwnerBusinessLogoThumb(imageUrl: logoUrl),
              const SizedBox(width: AppResources.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            groupKey,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (showPending) _PendingBadge(),
                        if (showVerified) _VerifiedBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      categoryLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locationSubtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppResources.spacingM),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.visibility_outlined,
                  label: 'Monthly Views',
                  value: viewsLabel,
                ),
              ),
              const SizedBox(width: AppResources.spacingM),
              Expanded(
                child: _StatBox(
                  icon: Icons.star_outline_rounded,
                  label: 'Avg. Rating',
                  value: ratingLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppResources.spacingM),
          Row(
            children: [
              Expanded(
                flex: 11,
                child: SizedBox(
                  height: AppResources.buttonHeightM,
                  child: OutlinedButton(
                    onPressed: () => showOwnerBusinessLocationsSheet(
                      context: context,
                      locations: list,
                      onPresenceSelected: onPresenceSelected,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: kOwnerBusinessCardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'View Locations',
                        maxLines: 1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppResources.spacingS),
              Expanded(
                flex: 9,
                child: SizedBox(
                  height: AppResources.buttonHeightM,
                  child: ElevatedButton(
                    onPressed: () => onPresenceSelected(primary.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Manage',
                        maxLines: 1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
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

class OwnerBusinessLogoThumb extends StatelessWidget {
  const OwnerBusinessLogoThumb({super.key, required this.imageUrl});

  final String imageUrl;

  bool get _isNetwork =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 56,
        child: _isNetwork
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _logoPlaceholder(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return ColoredBox(
                    color: AppColors.backgroundLight,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              )
            : _logoPlaceholder(),
      ),
    );
  }

  Widget _logoPlaceholder() {
    return const ColoredBox(
      color: AppColors.backgroundLight,
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          color: AppColors.textTertiary,
          size: 28,
        ),
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kOwnerBusinessPendingBadgeBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Pending',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: kOwnerBusinessPendingBadgeFg,
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 6),
      child: Icon(
        Icons.verified,
        size: 22,
        color: AppColors.brandSecondary,
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

BusinessPresence primaryPresenceInGroup(
  List<BusinessPresence> group,
  String? currentPresenceId,
) {
  if (currentPresenceId != null) {
    try {
      return group.firstWhere((p) => p.id == currentPresenceId);
    } catch (_) {}
  }
  return group.first;
}

double? averageRating(List<BusinessPresence> list) {
  final ratings = list
      .map((p) => p.rating)
      .whereType<double>()
      .where((r) => r > 0)
      .toList();
  if (ratings.isEmpty) return null;
  return ratings.reduce((a, b) => a + b) / ratings.length;
}

String locationSummaryLine(List<BusinessPresence> list) {
  final n = list.length;
  final countPart = n == 1 ? '1 Location' : '$n Locations';
  final city = list.map((p) => p.city).whereType<String>().firstWhere(
        (c) => c.trim().isNotEmpty,
        orElse: () => '',
      );
  if (city.isEmpty) return countPart;
  return '$countPart • $city';
}
