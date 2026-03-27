import 'package:flutter/material.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';

class BusinessOwnerOnboardingPage extends StatelessWidget {
  const BusinessOwnerOnboardingPage({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingL,
            vertical: AppResources.spacingL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppResources.spacingL),
              Text(
                'Welcome, Business Owner!',
                style: AppFonts.largeTitle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppResources.spacingM),
              Text(
                'Before you start, complete these steps to unlock your dashboard.',
                style: AppFonts.body(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppResources.spacingXL),
              _StepCard(
                icon: Icons.verified_user_outlined,
                title: 'Verify your email',
                subtitle: 'Use the verification link sent to your inbox.',
              ),
              const SizedBox(height: AppResources.spacingM),
              _StepCard(
                icon: Icons.description_outlined,
                title: 'Upload legal documents',
                subtitle:
                    'Each business must submit required documents for review.',
              ),
              const SizedBox(height: AppResources.spacingM),
              _StepCard(
                icon: Icons.approval_outlined,
                title: 'Wait for approval',
                subtitle:
                    'Your dashboard tools unlock after document approval.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: AppResources.buttonHeightM,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppResources.spacingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: AppFonts.button(color: AppColors.textOnPrimary)
                        .copyWith(height: 1.0),
                    textAlign: TextAlign.center,
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

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brandPrimary),
          const SizedBox(width: AppResources.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.body(color: AppColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppResources.spacingXS),
                Text(
                  subtitle,
                  style: AppFonts.bodySmall(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
