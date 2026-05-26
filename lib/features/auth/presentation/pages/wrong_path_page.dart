import 'package:flutter/material.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../choose_path/presentation/pages/choose_path_page.dart';

/// Shown when the user signed in on the wrong path (e.g. community member on
/// business sign-in, or business owner on community sign-in). Offers a clear
/// way to go back and choose the correct path.
class WrongPathPage extends StatelessWidget {
  /// Whether they tried to use the business path (so we show "you're a community member" message).
  final bool usedBusinessPath;

  const WrongPathPage({
    super.key,
    required this.usedBusinessPath,
  });

  @override
  Widget build(BuildContext context) {
    final String title;
    final String message;
    if (usedBusinessPath) {
      title = 'This is the Business sign-in';
      message =
          "Your account is a community member account. To sign in as a community member, use the regular 'Sign in' option from the previous screen. If you own a business and want to manage it here, sign up or sign in using the Business path with your business account.";
    } else {
      title = 'This is the Community sign-in';
      message =
          "Your account is a business owner account. To sign in as a business owner and manage your business, go back and choose 'Business owner' then sign in there. Use this Community sign-in only for personal (community member) accounts.";
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => _goBackToChoosePath(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingL,
            vertical: AppResources.spacingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppResources.spacingL),
              Icon(
                Icons.info_outline,
                size: 56,
                color: AppColors.brandPrimary.withValues(alpha: 0.8),
              ),
              const SizedBox(height: AppResources.spacingL),
              Text(
                title,
                style: AppFonts.largeTitle(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppResources.spacingM),
              Text(
                message,
                style: AppFonts.body(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: AppResources.buttonHeightM,
                child: ElevatedButton(
                  onPressed: () => _goBackToChoosePath(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                    ),
                  ),
                  child: Text(
                    'Go back to sign in',
                    style: AppFonts.button(color: AppColors.textOnPrimary)
                        .copyWith(height: 1.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goBackToChoosePath(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ChoosePathPage()),
      (route) => false,
    );
  }
}
