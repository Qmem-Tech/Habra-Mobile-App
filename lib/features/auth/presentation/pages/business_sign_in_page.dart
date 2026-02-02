import 'package:flutter/material.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import 'business_basics_page.dart';

class BusinessSignInPage extends StatelessWidget {
  const BusinessSignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppResources.spacingXL),

              // Title with highlighted "Business"
              RichText(
                text: TextSpan(
                  style: AppFonts.largeTitle(color: AppColors.textPrimary),
                  children: [
                    TextSpan(
                      text: 'Business ',
                      style: AppFonts.largeTitle(color: AppColors.brandSecondary),
                    ),
                    const TextSpan(text: 'account sign in'),
                  ],
                ),
              ),
              const SizedBox(height: AppResources.spacingM),

              // Description
              Text(
                'Discover local businesses & connect with your people.',
                style: AppFonts.body(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppResources.spacingXXL),

              // Continue with Email button
              _buildSignInButton(
                icon: Icons.email,
                label: 'Continue with Email',
                backgroundColor: AppColors.brandPrimary,
                textColor: AppColors.textOnPrimary,
                iconColor: AppColors.textOnPrimary,
                onPressed: () {
                  // TODO: Navigate to business email sign in
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BusinessBasicsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppResources.spacingM),

              // OR separator
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha:0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                    child: Text(
                      'or',
                      style: AppFonts.bodySmall(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha:0.3))),
                ],
              ),
              const SizedBox(height: AppResources.spacingM),

              // Continue with Google button
              _buildSignInButton(
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                backgroundColor: AppColors.backgroundWhite,
                textColor: AppColors.textSecondary,
                iconColor: AppColors.textSecondary,
                borderColor: AppColors.backgroundGrey,
                onPressed: () {
                  // TODO: Implement Google sign in for business
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Google sign in coming soon')),
                  );
                },
              ),
              const SizedBox(height: AppResources.spacingM),

              // Continue with Apple button
              _buildSignInButton(
                icon: Icons.apple,
                label: 'Continue with Apple',
                backgroundColor: AppColors.textPrimary,
                textColor: AppColors.textOnPrimary,
                iconColor: AppColors.textOnPrimary,
                onPressed: () {
                  // TODO: Implement Apple sign in for business
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Apple sign in coming soon')),
                  );
                },
              ),
              const SizedBox(height: AppResources.spacingXXL),

              // Login prompt
              Center(
                child: RichText(
                  text: TextSpan(
                    style: AppFonts.body(color: AppColors.textPrimary),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            // TODO: Navigate to business login page
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Business login coming soon')),
                            );
                          },
                          child: Text(
                            'Log in',
                            style: AppFonts.body(color: AppColors.brandSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    Color? borderColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: AppResources.buttonHeightM,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          side: borderColor != null
              ? BorderSide(color: borderColor, width: 1)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppResources.radiusM),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: AppResources.iconSizeM),
            const SizedBox(width: AppResources.spacingM),
            Text(
              label,
              style: AppFonts.button(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
