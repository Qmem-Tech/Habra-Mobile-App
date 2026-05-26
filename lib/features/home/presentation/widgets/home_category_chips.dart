import 'package:flutter/material.dart';
import '../../../../core/navigation/main_navigation_wrapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../explore/presentation/pages/deals_page.dart';

/// Horizontal category shortcuts (home mock: Food, Events, Deals).
class HomeCategoryChips extends StatelessWidget {
  const HomeCategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _Chip(
            label: 'Food & Drink',
            backgroundColor: AppColors.customerHomePrimary,
            textColor: Colors.white,
            icon: Icons.restaurant_outlined,
            onTap: () => MainNavigationWrapper.navigateToTab(context, 2),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Events',
            backgroundColor: const Color(0xFFEDE7F6),
            textColor: const Color(0xFF5E35B1),
            icon: Icons.event_outlined,
            onTap: () => MainNavigationWrapper.navigateToTab(context, 1),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Deals',
            backgroundColor: const Color(0xFFFFF3E0),
            textColor: const Color(0xFFEF6C00),
            icon: Icons.local_offer_outlined,
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(builder: (_) => const DealsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
