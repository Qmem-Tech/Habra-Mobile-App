import 'package:flutter/material.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';

class EmailVerificationPage extends StatelessWidget {
  final String email;

  const EmailVerificationPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingL,
            vertical: AppResources.spacingM,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppResources.spacingXXL),

              // Mailbox illustration
              _buildMailboxIllustration(),
              const SizedBox(height: AppResources.spacingXXL),

              // Title
              Text(
                'Check your email',
                style: AppFonts.largeTitle(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppResources.spacingM),

              // Instructions
              Text(
                'We sent a verification email to. Please tap the link inside that email to continue',
                style: AppFonts.body(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppResources.spacingXXL),

              // Check my inbox button
              SizedBox(
                width: double.infinity,
                height: AppResources.buttonHeightM,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Open email app
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening email app...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                    ),
                  ),
                  child: Text(
                    'Check my inbox',
                    style: AppFonts.button(color: AppColors.textOnPrimary).copyWith(
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: AppResources.spacingM),

              // Resend email button
              SizedBox(
                width: double.infinity,
                height: AppResources.buttonHeightM,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Resend verification email
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification email resent')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.backgroundGrey),
                    padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                    ),
                  ),
                  child: Text(
                    'Resend email',
                    style: AppFonts.button(color: AppColors.textPrimary).copyWith(
                      height: 1.0,
                    ),
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

  Widget _buildMailboxIllustration() {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mailbox body
          Container(
            width: 120,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              border: Border.all(color: AppColors.textPrimary, width: 2),
              borderRadius: BorderRadius.circular(AppResources.radiusS),
            ),
          ),
          // Mailbox flag
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 40,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.brandSecondary,
                borderRadius: BorderRadius.circular(AppResources.radiusS),
              ),
            ),
          ),
          // Mailbox post
          Positioned(
            bottom: 0,
            child: Container(
              width: 8,
              height: 60,
              color: AppColors.textPrimary,
            ),
          ),
          // Envelope
          Positioned(
            right: 10,
            child: Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                border: Border.all(color: AppColors.textPrimary, width: 1),
              ),
              child: Stack(
                children: [
                  // Papers inside
                  Positioned(
                    left: 4,
                    top: 4,
                    child: Container(
                      width: 52,
                      height: 32,
                      color: AppColors.backgroundGrey,
                    ),
                  ),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      width: 48,
                      height: 28,
                      color: AppColors.brandSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
