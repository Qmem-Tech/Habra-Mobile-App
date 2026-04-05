import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Horizontal tab bar for Analytics, Deals, Jobs, Reviews (text + underline, design mock).
class DashboardTabBar extends StatelessWidget {
  const DashboardTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<String> _labels = ['Analytics', 'Deals', 'Jobs', 'Reviews'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8E8E8)),
        ),
      ),
      child: Row(
        children: List.generate(_labels.length, (index) {
          final isSelected = index == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _labels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.brandPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brandPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
