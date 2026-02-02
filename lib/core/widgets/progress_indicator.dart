import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Custom progress indicator for onboarding and similar flows
///
/// Usage:
/// ```dart
/// AppProgressIndicator(
///   currentIndex: 1,
///   totalPages: 3,
/// )
/// ```
class AppProgressIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalPages;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? height;
  final double? activeWidth;
  final double? inactiveWidth;

  const AppProgressIndicator({
    super.key,
    required this.currentIndex,
    required this.totalPages,
    this.activeColor,
    this.inactiveColor,
    this.height,
    this.activeWidth,
    this.inactiveWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => _buildIndicator(index == currentIndex),
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: height ?? 4,
      width: isActive ? (activeWidth ?? 32) : (inactiveWidth ?? 8),
      decoration: BoxDecoration(
        color: isActive
            ? (activeColor ?? AppColors.progressActive)
            : (inactiveColor ?? AppColors.progressInactive),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
