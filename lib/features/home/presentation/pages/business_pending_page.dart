import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/domain/entities/user.dart';
import 'business_owner_wrapper_page.dart';

/// Shown when a business is under review (not yet visible to the community).
/// Part of business owner journey: "Your Business Is Pending!" with Go To Dashboard.
class BusinessPendingPage extends StatelessWidget {
  final User user;
  final String? businessName;

  const BusinessPendingPage({
    super.key,
    required this.user,
    this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    final name = businessName ?? 'Your business';

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingL),
          child: Column(
            children: [
              const SizedBox(height: 48),
              _buildIcon(context),
              const SizedBox(height: 28),
              const Text(
                'Your Business Is Pending!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '$name is currently under review and not yet visible to the community.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: AppResources.spacingXXL),
                child: AppButton(
                  text: 'Go To Dashboard',
                  onPressed: () => _goToDashboard(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Center(
      child: Image.asset(
        AppAssets.businessOwnerPendingReview,
        width: 120,
        height: 120,
        errorBuilder: (_, __, ___) => Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.brandSecondary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.schedule,
            size: 64,
            color: AppColors.brandSecondary,
          ),
        ),
      ),
    );
  }

  void _goToDashboard(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessOwnerWrapperPage(user: user),
      ),
      (route) => false,
    );
  }
}
