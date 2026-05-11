import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/dashboard_deal.dart';
import '../widgets/empty_state_widget.dart';
import '../../../../core/resources/app_assets.dart';

class DashboardDealsTab extends StatelessWidget {
  const DashboardDealsTab({
    super.key,
    required this.deals,
    this.filter = DashboardDealStatus.active,
    required this.onFilterChanged,
    required this.onCreateDeal,
    this.onEdit,
    this.onPause,
    this.onStats,
    this.onDelete,
  });

  final List<DashboardDeal> deals;
  final DashboardDealStatus? filter;
  final ValueChanged<DashboardDealStatus?> onFilterChanged;
  final VoidCallback onCreateDeal;
  final void Function(DashboardDeal)? onEdit;
  final void Function(DashboardDeal)? onPause;
  final void Function(DashboardDeal)? onStats;
  final void Function(DashboardDeal)? onDelete;

  static Color _dealTypeColor(String label) {
    if (label.toLowerCase().contains('buy') || label.toLowerCase().contains('get')) {
      return AppColors.success.withValues(alpha: 0.25);
    }
    if (label.toLowerCase().contains('%')) {
      return AppColors.info.withValues(alpha: 0.25);
    }
    return AppColors.brandSecondary.withValues(alpha: 0.25);
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = deals
        .where((d) =>
            d.status == DashboardDealStatus.active ||
            d.status == DashboardDealStatus.inactive)
        .length;
    final expiredCount = deals.where((d) => d.status == DashboardDealStatus.expired).length;
    final draftCount = deals.where((d) => d.status == DashboardDealStatus.draft).length;
    final effectiveFilter = filter ?? DashboardDealStatus.active;
    final filteredDeals = deals.where((d) {
      switch (effectiveFilter) {
        case DashboardDealStatus.active:
          return d.status == DashboardDealStatus.active ||
              d.status == DashboardDealStatus.inactive;
        case DashboardDealStatus.expired:
          return d.status == DashboardDealStatus.expired;
        case DashboardDealStatus.draft:
          return d.status == DashboardDealStatus.draft;
        case DashboardDealStatus.inactive:
          return d.status == DashboardDealStatus.inactive;
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
          child: Row(
            children: [
              _FilterChip(
                label: 'Active ($activeCount)',
                selected: effectiveFilter == DashboardDealStatus.active,
                onTap: () => onFilterChanged(DashboardDealStatus.active),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Expired ($expiredCount)',
                selected: effectiveFilter == DashboardDealStatus.expired,
                onTap: () => onFilterChanged(DashboardDealStatus.expired),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Drafts ($draftCount)',
                selected: effectiveFilter == DashboardDealStatus.draft,
                onTap: () => onFilterChanged(DashboardDealStatus.draft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filteredDeals.isEmpty
              ? EmptyStateWidget(
                  illustrationPath: AppAssets.dashboardNoDeals,
                  title: 'No Deals Yet',
                  description: 'You haven\'t posted any deals for your business. '
                      'Start connecting with the community by offering a special discount today.',
                  actionLabel: 'Create a Deal',
                  onAction: onCreateDeal,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                  itemCount: filteredDeals.length,
                  itemBuilder: (context, index) {
                    final deal = filteredDeals[index];
                    return _DealCard(
                      deal: deal,
                      onEdit: () => onEdit?.call(deal),
                      onPause: () => onPause?.call(deal),
                      onStats: () => onStats?.call(deal),
                      onDelete: onDelete == null ? null : () => onDelete!(deal),
                    );
                  },
                ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandPrimary : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({
    required this.deal,
    this.onEdit,
    this.onPause,
    this.onStats,
    this.onDelete,
  });

  final DashboardDeal deal;
  final VoidCallback? onEdit;
  final VoidCallback? onPause;
  final VoidCallback? onStats;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final typeColor = DashboardDealsTab._dealTypeColor(deal.dealTypeLabel);
    final statusLabel = switch (deal.status) {
      DashboardDealStatus.active => 'Active',
      DashboardDealStatus.inactive => 'Paused',
      DashboardDealStatus.expired => 'Expired',
      DashboardDealStatus.draft => 'Draft',
    };
    final statusColor = switch (deal.status) {
      DashboardDealStatus.active => AppColors.success.withValues(alpha: 0.2),
      DashboardDealStatus.inactive => AppColors.textTertiary.withValues(alpha: 0.2),
      DashboardDealStatus.expired => AppColors.error.withValues(alpha: 0.15),
      DashboardDealStatus.draft => AppColors.info.withValues(alpha: 0.2),
    };
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppResources.radiusL),
                  bottomLeft: Radius.circular(AppResources.radiusL),
                ),
                child: Image.network(
                  deal.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 100,
                    color: AppColors.backgroundGrey,
                    child: const Icon(Icons.sell, color: AppColors.textTertiary),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: typeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              deal.dealTypeLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        deal.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        deal.validityDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${deal.redeemedCount} Redeemed',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandSecondary,
                            ),
                          ),
                          if (deal.expiryDate != null)
                            Text(
                              deal.expiryDateShort,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: (deal.status == DashboardDealStatus.active ||
                          deal.status == DashboardDealStatus.inactive)
                      ? onPause
                      : null,
                  icon: Icon(
                    deal.status == DashboardDealStatus.inactive
                        ? Icons.play_circle_outline
                        : Icons.pause_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    deal.status == DashboardDealStatus.inactive ? 'Resume' : 'Pause',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: onStats,
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('Stats'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
