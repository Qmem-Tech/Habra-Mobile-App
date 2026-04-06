import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/location/session_device_location_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/deal.dart';
import '../../domain/entities/listing_category.dart';
import '../../domain/usecases/get_active_listing_categories_usecase.dart';
import '../bloc/deals_cubit.dart';
import '../bloc/deals_state.dart';
import '../widgets/deal_card.dart';
import 'deal_detail_page.dart';

class DealsPage extends StatefulWidget {
  const DealsPage({super.key});

  @override
  State<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedListingCategoryId;
  List<ListingCategory> _listingCategories = [];
  bool _listingCategoriesLoading = true;
  String _currentLocation = 'Washington, D.C.';

  void _reloadDeals(BuildContext context) {
    final loc = SessionDeviceLocationCubit.tryLabel(context) ?? _currentLocation;
    context.read<DealsCubit>().loadDeals(location: loc);
  }

  @override
  void initState() {
    super.initState();
    _loadListingCategories();
  }

  Future<void> _loadListingCategories() async {
    final result = await di.sl<GetActiveListingCategoriesUseCase>()();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _listingCategoriesLoading = false),
      (list) => setState(() {
        _listingCategories = list;
        _listingCategoriesLoading = false;
      }),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionCubit = SessionDeviceLocationCubit.maybeOf(context);
    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text(
          'Deals',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilters(),
          Expanded(
            child: BlocBuilder<DealsCubit, DealsState>(
              builder: (context, state) {
                if (state is DealsLoading) {
                  return const HabraCircularLoader(fullScreen: true);
                }

                if (state is DealsError) {
                  return _buildErrorView(state.message);
                }

                if (state is DealsLoaded) {
                  if (state.deals.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildDealsList(state.deals);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );

    final synced = sessionCubit == null
        ? scaffold
        : BlocListener<SessionDeviceLocationCubit, SessionDeviceLocationState>(
            listenWhen: (prev, curr) => curr is SessionDeviceLocationReady,
            listener: (context, state) {
              if (state is SessionDeviceLocationReady) {
                setState(
                  () => _currentLocation = state.location.fullDisplayName,
                );
                _reloadDeals(context);
              }
            },
            child: scaffold,
          );

    return BlocProvider(
      create: (context) {
        final cubit = di.sl<DealsCubit>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final loc = SessionDeviceLocationCubit.tryLabel(context) ??
              _currentLocation;
          cubit.loadDeals(location: loc);
        });
        return cubit;
      },
      child: synced,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.backgroundGrey.withValues(alpha:0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.textSecondary.withValues(alpha:0.7), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Find business, event...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    if (_listingCategoriesLoading) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return BlocBuilder<DealsCubit, DealsState>(
      builder: (context, state) {
        final availableCategoryIds = state is DealsLoaded
            ? state.deals
                .expand((d) => d.business.listingCategoryIds)
                .where((id) => id.trim().isNotEmpty)
                .toSet()
            : <String>{};

        final visibleCategories = availableCategoryIds.isEmpty
            ? _listingCategories
            : _listingCategories
                .where((c) => availableCategoryIds.contains(c.id))
                .toList();

        if (_selectedListingCategoryId != null &&
            !visibleCategories.any((c) => c.id == _selectedListingCategoryId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _selectedListingCategoryId = null);
          });
        }

        return SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _dealCategoryChip(label: 'All', id: null),
              ...visibleCategories
                  .map((c) => _dealCategoryChip(label: c.name, id: c.id)),
            ],
          ),
        );
      },
    );
  }

  Widget _dealCategoryChip({required String label, required String? id}) {
    final isSelected = _selectedListingCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedListingCategoryId = id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandPrimary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.brandPrimary : AppColors.backgroundGrey,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDealsList(List<Deal> deals) {
    final cid = _selectedListingCategoryId;
    final scoped = cid == null || cid.isEmpty
        ? deals
        : deals.where((d) => d.business.listingCategoryIds.contains(cid)).toList();
    if (scoped.isEmpty) {
      return _buildEmptyState();
    }
    final hotDeals = scoped.where((d) => d.type == DealType.hotDeal).toList();
    final happyHour = scoped.where((d) => d.type == DealType.happyHour).toList();
    final otherDeals = scoped
        .where((d) => d.type != DealType.hotDeal && d.type != DealType.happyHour)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        _reloadDeals(context);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (hotDeals.isNotEmpty) ...[
            _buildSectionHeader('Hot Deals', '🔥'),
            const SizedBox(height: 12),
            ...hotDeals.map((deal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DealCard(
                  deal: deal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DealDetailPage(dealId: deal.id),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
          if (happyHour.isNotEmpty) ...[
            _buildSectionHeader('Happy Hour', '🍹'),
            const SizedBox(height: 12),
            ...happyHour.map((deal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DealCard(
                  deal: deal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DealDetailPage(dealId: deal.id),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
          if (otherDeals.isNotEmpty) ...[
            if (hotDeals.isNotEmpty || happyHour.isNotEmpty)
              const SizedBox(height: 24),
            _buildSectionHeader('All Deals', '🏷️'),
            const SizedBox(height: 12),
            ...otherDeals.map((deal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DealCard(
                  deal: deal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DealDetailPage(dealId: deal.id),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String emoji) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(emoji, style: const TextStyle(fontSize: 20)),
      ],
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Error loading deals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          const Text(
            'No deals found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
