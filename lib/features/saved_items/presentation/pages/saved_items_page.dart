import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/resources/app_assets.dart';
import '../../domain/entities/saved_item.dart';
import '../bloc/saved_items_cubit.dart';
import '../bloc/saved_items_state.dart';

enum SavedItemsFilter { all, events, deals }

/// Saved Items screen with filter tabs (All, Events, Deals), list from backend, empty state.
class SavedItemsPage extends StatefulWidget {
  const SavedItemsPage({super.key});

  @override
  State<SavedItemsPage> createState() => _SavedItemsPageState();
}

class _SavedItemsPageState extends State<SavedItemsPage> {
  SavedItemsFilter _filter = SavedItemsFilter.all;

  SavedItemType? get _filterType {
    switch (_filter) {
      case SavedItemsFilter.all:
        return null;
      case SavedItemsFilter.events:
        return SavedItemType.event;
      case SavedItemsFilter.deals:
        return SavedItemType.deal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          title: const Text('Saved Items'),
          backgroundColor: AppColors.backgroundWhite,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: Column(
          children: [
            _FilterTabs(
              selected: _filter,
              onSelected: (v) {
                setState(() => _filter = v);
                final type = v == SavedItemsFilter.all
                    ? null
                    : (v == SavedItemsFilter.deals
                        ? SavedItemType.deal
                        : SavedItemType.event);
                context.read<SavedItemsCubit>().loadSavedItems(filterType: type);
              },
            ),
            Expanded(
              child: BlocBuilder<SavedItemsCubit, SavedItemsState>(
                builder: (context, state) {
                  if (state is SavedItemsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is SavedItemsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message),
                          const SizedBox(height: AppResources.spacingM),
                          TextButton(
                            onPressed: () => context
                                .read<SavedItemsCubit>()
                                .loadSavedItems(filterType: _filterType),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is SavedItemsLoaded && state.items.isEmpty) {
                    return EmptyStateWidget(
                      illustrationPath: AppAssets.savedItemsEmpty,
                      title: 'Nothing saved yet',
                      message:
                          'Keep track of your favorite Habesha restaurants, upcoming cultural events, and exclusive deals.',
                      buttonLabel: 'Start Exploring',
                      onButtonTap: () => Navigator.pop(context),
                    );
                  }
                  if (state is SavedItemsLoaded) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<SavedItemsCubit>()
                            .loadSavedItems(filterType: _filterType);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppResources.spacingM),
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _SavedItemCard(
                            item: item,
                            onUnsave: () => context
                                .read<SavedItemsCubit>()
                                .removeItem(item.id),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
    );
  }
}

class _SavedItemCard extends StatelessWidget {
  final SavedItem item;
  final VoidCallback onUnsave;

  const _SavedItemCard({
    required this.item,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppResources.spacingM),
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppResources.radiusM),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(
                    item.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: AppResources.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title ?? (item.itemType == SavedItemType.event ? 'Event' : 'Deal'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                if (item.subtitle != null)
                  Text(
                    item.subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark, color: AppColors.brandSecondary),
            onPressed: onUnsave,
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.backgroundGrey.withValues(alpha: 0.5),
      child: const Icon(Icons.image_outlined, color: AppColors.textTertiary),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final SavedItemsFilter selected;
  final ValueChanged<SavedItemsFilter> onSelected;

  const _FilterTabs({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppResources.spacingL,
        vertical: AppResources.spacingM,
      ),
      child: Row(
        children: [
          _TabChip(
            label: 'All',
            isSelected: selected == SavedItemsFilter.all,
            onTap: () => onSelected(SavedItemsFilter.all),
          ),
          const SizedBox(width: AppResources.spacingS),
          _TabChip(
            label: 'Events',
            isSelected: selected == SavedItemsFilter.events,
            onTap: () => onSelected(SavedItemsFilter.events),
          ),
          const SizedBox(width: AppResources.spacingS),
          _TabChip(
            label: 'Deals',
            isSelected: selected == SavedItemsFilter.deals,
            onTap: () => onSelected(SavedItemsFilter.deals),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppResources.radiusXXL),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingL,
            vertical: AppResources.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandPrimary : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppResources.radiusXXL),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
