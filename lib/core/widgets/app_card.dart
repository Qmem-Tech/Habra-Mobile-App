import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../resources/app_resources.dart';

/// Reusable card widget with consistent styling
///
/// Usage:
/// ```dart
/// AppCard(
///   child: Text('Card content'),
/// )
/// ```
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: borderRadius ?? BorderRadius.circular(AppResources.radiusL),
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: elevation!,
                  offset: Offset(0, elevation! / 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(AppResources.radiusL),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppResources.spacingL),
            child: child,
          ),
        ),
      ),
    );
  }
}
