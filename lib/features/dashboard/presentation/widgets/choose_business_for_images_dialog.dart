import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../home/domain/entities/business_presence.dart';

/// Step 1: Choose a business from the list.
/// Step 2: If the business has required images, show confirmation and dismiss.
///         If not, show the upload dialog.
class ChooseBusinessForImagesDialog extends StatelessWidget {
  const ChooseBusinessForImagesDialog({
    super.key,
    required this.presences,
  });

  final List<BusinessPresence> presences;

  @override
  Widget build(BuildContext context) {
    final businesses = presences.where((p) => p.id != 'all').toList();
    if (businesses.isEmpty) return const SizedBox.shrink();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Padding(
        padding: const EdgeInsets.all(AppResources.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront, color: AppColors.brandPrimary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose Business',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a business to manage images',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: businesses.length,
                itemBuilder: (context, index) {
                  final p = businesses[index];
                  final needsImages = !p.hasRequiredImages;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onBusinessSelected(context, p),
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(AppResources.radiusM),
                            border: Border.all(
                              color: needsImages
                                  ? AppColors.warning.withValues(alpha: 0.5)
                                  : AppColors.backgroundGrey,
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: p.logoUrl != null && p.logoUrl!.isNotEmpty
                                    ? Image.network(
                                        p.logoUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                      )
                                    : p.backgroundUrl != null && p.backgroundUrl!.isNotEmpty
                                        ? Image.network(
                                            p.backgroundUrl!,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                          )
                                        : _buildPlaceholder(),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.displayName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p.locationDisplay,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: needsImages
                                      ? AppColors.warning.withValues(alpha: 0.2)
                                      : AppColors.success.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  needsImages ? 'Add images' : 'Complete',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: needsImages ? AppColors.warning : AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.backgroundGrey,
      child: Icon(Icons.store, color: AppColors.textTertiary),
    );
  }

  void _onBusinessSelected(BuildContext context, BusinessPresence presence) {
    Navigator.of(context, rootNavigator: true).pop(presence);
  }
}
