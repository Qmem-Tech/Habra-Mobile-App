import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/resources/app_assets.dart';
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
        Expanded(
          child: Divider(
            color: AppColors.backgroundGrey.withValues(alpha: 0.85),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
          child: Text(
            'or',
            style: AppFonts.bodySmall(color: AppColors.textTertiary),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.backgroundGrey.withValues(alpha: 0.85),
            thickness: 1,
          ),
        ),
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
    this.height = AppResources.buttonHeightM,
    this.borderRadius = AppResources.radiusM,
    this.foregroundColor,
    this.borderColor,
  });

  final VoidCallback? onPressed;
  final String label;
  final double height;
  final double borderRadius;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? AppColors.textPrimary;
    final border = borderColor ?? AppColors.backgroundGrey;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          backgroundColor: AppColors.backgroundWhite,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              AppAssets.googleLogoSvg,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: AppResources.spacingM),
            Text(
              label,
              style: AppFonts.button(color: fg).copyWith(
                height: 1.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
