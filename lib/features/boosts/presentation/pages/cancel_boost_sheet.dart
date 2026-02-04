import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/resources/app_assets.dart';

/// Bottom sheet to confirm boost cancellation with optional reason.
class CancelBoostSheet extends StatefulWidget {
  const CancelBoostSheet({
    super.key,
    required this.boostId,
    required this.listingName,
    required this.listingSubtitle,
    this.listingImageUrl,
    required this.onCancelBoost,
  });

  final String boostId;
  final String listingName;
  final String listingSubtitle;
  final String? listingImageUrl;
  final Future<void> Function() onCancelBoost;

  @override
  State<CancelBoostSheet> createState() => _CancelBoostSheetState();
}

class _CancelBoostSheetState extends State<CancelBoostSheet> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppResources.spacingM,
        right: AppResources.spacingM,
        top: AppResources.spacingM,
        bottom: MediaQuery.of(context).padding.bottom + AppResources.spacingM,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppResources.radiusXL)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cancel Boost?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildListingRow(),
            const SizedBox(height: 20),
            _buildImplications(),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reason (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Why are you cancelling?',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppResources.radiusM),
                  borderSide: BorderSide(color: AppColors.backgroundGrey),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: AppResources.buttonHeightM,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppResources.radiusM),
                  ),
                ),
                onPressed: _isLoading ? null : _confirmCancel,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                        ),
                      )
                    : const Text(
                        'Cancel Boost',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingRow() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppResources.radiusM),
          child: widget.listingImageUrl != null && widget.listingImageUrl!.isNotEmpty
              ? Image.network(
                  widget.listingImageUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderImage(),
                )
              : _placeholderImage(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.listingName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.listingSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 72,
      height: 72,
      color: AppColors.backgroundLight,
      child: Image.asset(
        AppAssets.boostsCancelListingPlaceholder,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, color: AppColors.textTertiary),
      ),
    );
  }

  Widget _buildImplications() {
    return Column(
      children: [
        _implicationRow(
          Icons.search_off,
          'Listing no longer featured in search results',
        ),
        const SizedBox(height: 12),
        _implicationRow(
          Icons.money_off,
          'No refunds for remaining boost time',
        ),
        const SizedBox(height: 12),
        _implicationRow(
          Icons.calendar_today,
          'Auto-renew disabled immediately',
        ),
      ],
    );
  }

  Widget _implicationRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmCancel() async {
    setState(() => _isLoading = true);
    await widget.onCancelBoost();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}
