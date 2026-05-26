import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../resources/app_resources.dart';
import 'app_button.dart';

/// Reusable empty state with optional illustration, title, message and CTA.
/// Use for Saved Items, My Reviews, and other list empty states.
class EmptyStateWidget extends StatelessWidget {
  final String illustrationPath;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyStateWidget({
    super.key,
    required this.illustrationPath,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppResources.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              illustrationPath,
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppResources.radiusL),
                  ),
                  child: Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: AppColors.textTertiary,
                  ),
                );
              },
            ),
            const SizedBox(height: AppResources.spacingXL),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ) ??
                  const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppResources.spacingS),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ) ??
                  const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButtonTap != null) ...[
              const SizedBox(height: AppResources.spacingXL),
              AppButton(
                text: buttonLabel!,
                onPressed: onButtonTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
