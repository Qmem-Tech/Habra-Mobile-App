import 'package:flutter/material.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../domain/entities/user.dart';
import '../../../home/presentation/pages/business_owner_wrapper_page.dart';

class BusinessLivePage extends StatelessWidget {
  const BusinessLivePage({super.key});

  void _onGoToDashboard(BuildContext context) {
    // TODO: Get actual business user from registration
    final user = User(
      id: 'temp_business_id',
      email: 'business@example.com',
      name: 'Business Owner',
      role: UserRole.businessOwner,
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => BusinessOwnerWrapperPage(user: user),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingL,
            vertical: AppResources.spacingM,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon (star with checkmark)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.brandSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.textOnPrimary,
                  size: 60,
                ),
              ),
              const SizedBox(height: AppResources.spacingXXL),

              // Success message
              Text(
                'Your Business is Live!',
                style: AppFonts.largeTitle(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppResources.spacingM),

              // Description
              Text(
                'Abyssinia Coffee House is now visible to the community.',
                style: AppFonts.body(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppResources.spacingXXL),

              // Go To Dashboard button
              SizedBox(
                width: double.infinity,
                height: AppResources.buttonHeightM,
                child: ElevatedButton(
                  onPressed: () => _onGoToDashboard(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                    ),
                  ),
                  child: Text(
                    'Go To Dashboard',
                    style: AppFonts.button(color: AppColors.textOnPrimary),
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
