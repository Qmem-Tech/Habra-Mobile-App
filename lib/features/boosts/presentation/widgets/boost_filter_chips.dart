import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../domain/entities/boost_filter.dart';

class BoostFilterChips extends StatelessWidget {
  const BoostFilterChips({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  final BoostFilter currentFilter;
  final ValueChanged<BoostFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppResources.spacingM,
        vertical: AppResources.spacingS,
      ),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            isSelected: currentFilter == BoostFilter.all,
            onTap: () => onFilterChanged(BoostFilter.all),
          ),
          const SizedBox(width: AppResources.spacingS),
          _Chip(
            label: 'Active',
            isSelected: currentFilter == BoostFilter.active,
            onTap: () => onFilterChanged(BoostFilter.active),
          ),
          const SizedBox(width: AppResources.spacingS),
          _Chip(
            label: 'Past',
            isSelected: currentFilter == BoostFilter.past,
            onTap: () => onFilterChanged(BoostFilter.past),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.brandPrimary : AppColors.backgroundLight,
      borderRadius: BorderRadius.circular(AppResources.radiusXL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppResources.radiusXL),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingL,
            vertical: AppResources.spacingS + 2,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
