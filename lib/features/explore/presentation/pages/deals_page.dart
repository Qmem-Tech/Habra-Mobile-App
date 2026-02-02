import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/business_category.dart';
import '../../domain/entities/deal.dart';
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
  BusinessCategory _selectedCategory = BusinessCategory.all;
  final String _currentLocation = 'Washington, D.C.';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = di.sl<DealsCubit>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cubit.loadDeals(location: _currentLocation);
        });
        return cubit;
      },
      child: Scaffold(
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
      ),
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
    final categories = [
      BusinessCategory.all,
      BusinessCategory.food,
      BusinessCategory.beauty,
      BusinessCategory.grocery,
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
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
                  category.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDealsList(List<Deal> deals) {
    final hotDeals = deals.where((d) => d.type == DealType.hotDeal).toList();
    final happyHour = deals.where((d) => d.type == DealType.happyHour).toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DealsCubit>().loadDeals(location: _currentLocation);
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
