import 'package:flutter/material.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';

/// Shown on the Dashboard Events tab when Stripe Connect is not complete.
class PayoutSetupRequiredBanner extends StatelessWidget {
  const PayoutSetupRequiredBanner({
    super.key,
    required this.onSetUpPayouts,
    this.connectStatus,
  });

  final VoidCallback onSetUpPayouts;
  final String? connectStatus;

  @override
  Widget build(BuildContext context) {
    final isRestricted = connectStatus == 'restricted';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppResources.spacingM,
        12,
        AppResources.spacingM,
        0,
      ),
      child: Material(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppResources.radiusM),
            border: Border.all(
              color: AppColors.brandPrimary.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.brandPrimary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payout setup required',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isRestricted
                              ? 'Stripe needs more information before you can sell tickets. '
                                  'Complete payout setup to create events and receive your share of sales.'
                              : 'Before you can create events and sell tickets, connect your bank '
                                  'account so ticket payments can be sent to you automatically.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSetUpPayouts,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                    ),
                  ),
                  child: const Text(
                    'Set up payouts',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
