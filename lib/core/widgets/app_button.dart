import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../resources/app_resources.dart';

/// Reusable primary button widget
///
/// Usage:
/// ```dart
/// AppButton(
///   text: 'Get Started',
///   onPressed: () {},
/// )
/// ```
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? AppResources.buttonHeightM,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.brandPrimary,
          foregroundColor: textColor ?? AppColors.textOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppResources.radiusM),
          ),
          disabledBackgroundColor: AppColors.brandPrimary.withValues(alpha: AppResources.opacityDisabled),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppColors.textOnPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: AppResources.spacingS),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: AppTextStyles.buttonText(context, color: textColor),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Reusable secondary/outlined button widget
class AppOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final Color? borderColor;
  final Color? textColor;

  const AppOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? AppResources.buttonHeightM,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppColors.brandPrimary,
          side: BorderSide(
            color: borderColor ?? AppColors.brandPrimary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppResources.radiusM),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppColors.brandPrimary,
                  ),
                ),
              )
            : Text(
                text,
                style: AppTextStyles.buttonText(
                  context,
                  color: textColor ?? AppColors.brandPrimary,
                ),
              ),
      ),
    );
  }
}

/// Reusable text button widget
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final double? fontSize;

  const AppTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: textColor ?? AppColors.brandPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppResources.spacingM,
          vertical: AppResources.spacingS,
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.buttonText(
          context,
          color: textColor ?? AppColors.brandPrimary,
        ).copyWith(fontSize: fontSize),
      ),
    );
  }
}
