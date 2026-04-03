import 'package:flutter/material.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';

/// Horizontal rule with centered "or" (between OAuth and email/password).
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.backgroundGrey)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
          child: Text(
            'or',
            style: AppFonts.bodySmall(color: AppColors.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: AppColors.backgroundGrey)),
      ],
    );
  }
}

/// Outlined "Continue with Google" matching app button height.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue with Google',
  });

  final VoidCallback? onPressed;
  final String label;

  static const Color _gBlue = Color(0xFF4285F4);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppResources.buttonHeightM,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.backgroundGrey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppResources.radiusM),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: AppFonts.button(color: _gBlue).copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                height: 1,
              ),
            ),
            const SizedBox(width: AppResources.spacingM),
            Text(
              label,
              style: AppFonts.button(color: AppColors.textPrimary).copyWith(
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
