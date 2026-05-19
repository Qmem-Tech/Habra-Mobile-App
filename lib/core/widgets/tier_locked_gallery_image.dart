import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Gallery thumbnail with blur + lock when over the current plan's active limit.
class TierLockedGalleryImage extends StatelessWidget {
  const TierLockedGalleryImage({
    super.key,
    required this.child,
    required this.locked,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.onLockedTap,
  });

  final Widget child;
  final bool locked;
  final BorderRadius borderRadius;
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(borderRadius: borderRadius, child: child);

    if (locked) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: child,
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Not on plan',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (onLockedTap != null && locked) {
      return GestureDetector(onTap: onLockedTap, child: content);
    }
    return content;
  }
}

/// Short helper text for owner gallery editors.
Widget buildGalleryPlanSummary({
  required int totalCount,
  required int activeLimit,
  required int lockedCount,
}) {
  if (lockedCount <= 0) {
    return Text(
      '$totalCount of $activeLimit photos active on your plan.',
      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
    );
  }
  return Text(
    '$activeLimit visible on your listing · $lockedCount locked '
    '(remove extras or upgrade to show them).',
    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
  );
}
