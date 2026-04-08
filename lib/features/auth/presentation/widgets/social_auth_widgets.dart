import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' show AppleLogoPainter;

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

/// Black "Continue with Apple" matching [GoogleSignInButton] height, radius, and type scale.
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue with Apple',
    this.height = AppResources.buttonHeightM,
    this.borderRadius = AppResources.radiusM,
  });

  final VoidCallback? onPressed;
  final String label;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(borderRadius);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Opacity(
        opacity: enabled ? 1.0 : AppResources.opacityDisabled,
        child: Material(
          color: AppColors.textPrimary,
          borderRadius: radius,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            splashColor: AppColors.textOnPrimary.withValues(alpha: 0.12),
            highlightColor: AppColors.textOnPrimary.withValues(alpha: 0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CustomPaint(
                    painter: AppleLogoPainter(color: AppColors.textOnPrimary),
                  ),
                ),
                const SizedBox(width: AppResources.spacingM),
                Text(
                  label,
                  style: AppFonts.button(color: AppColors.textOnPrimary).copyWith(
                    height: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
