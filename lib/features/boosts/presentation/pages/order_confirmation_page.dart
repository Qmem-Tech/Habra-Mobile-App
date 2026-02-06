import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/widgets/app_button.dart';

/// Shown after successful boost payment. Summary card + "Go To Home".
class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({
    super.key,
    this.dealTitle,
    this.merchantName,
    this.dealImageUrl,
    this.expiresInDays,
    this.jobTitle,
    this.employerName,
    this.listingTitle,
  });

  final String? dealTitle;
  final String? merchantName;
  final String? dealImageUrl;
  final String? expiresInDays;
  final String? jobTitle;
  final String? employerName;
  final String? listingTitle;

  String get summaryTitle => dealTitle ?? jobTitle ?? listingTitle ?? 'Boost';
  String get subtitle => merchantName ?? employerName ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _goHome(context),
        ),
        title: const Text(
          'Order Confirmation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppResources.spacingL),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Image.asset(
              AppAssets.boostsOrderSuccess,
              height: 80,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.brandSecondary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 48, color: AppColors.brandSecondary),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.brandPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get ready for the gathering! Your tickets have been sent to your email.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildSummaryCard(context),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Go To Home',
                onPressed: () => _goHome(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
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
      child: Row(
        children: [
          if (dealImageUrl != null && dealImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              child: Image.network(
                dealImageUrl!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.backgroundLight,
                  child: const Icon(Icons.card_giftcard, color: AppColors.textTertiary),
                ),
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppResources.radiusM),
              ),
              child: const Icon(Icons.storefront, size: 40, color: AppColors.textTertiary),
            ),
          const SizedBox(width: AppResources.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summaryTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (expiresInDays != null && expiresInDays!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        expiresInDays!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
