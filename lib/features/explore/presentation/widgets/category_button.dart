import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/business_category.dart';

class CategoryButton extends StatelessWidget {
  final BusinessCategory category;
  final VoidCallback onTap;

  const CategoryButton({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(category.icon),
              size: 32,
              color: AppColors.brandPrimary,
            ),
            const SizedBox(height: 8),
            Text(
              category.displayName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'content_cut':
        return Icons.content_cut;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'gavel':
        return Icons.gavel;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'local_florist':
        return Icons.local_florist;
      default:
        return Icons.store;
    }
  }
}
