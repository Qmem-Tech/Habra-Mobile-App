import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/business_category.dart';
import '../../domain/entities/business_filters.dart';
import '../bloc/businesses_cubit.dart';
import '../bloc/businesses_state.dart';
import '../widgets/business_list_item_widget.dart';
import 'business_detail_page.dart';

class DirectoryPage extends StatefulWidget {
  final BusinessCategory? initialCategory;

  const DirectoryPage({super.key, this.initialCategory});

  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  final TextEditingController _searchController = TextEditingController();
  BusinessCategory _selectedCategory = BusinessCategory.all;
  final String _currentLocation = 'Washington, D.C.';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadBusinesses(BuildContext context) {
    final filters = _selectedCategory != BusinessCategory.all
        ? BusinessFilters(category: _selectedCategory)
        : null;
    context.read<BusinessesCubit>().loadBusinesses(
          location: _currentLocation,
          filters: filters,
          searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = di.sl<BusinessesCubit>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadBusinesses(context);
        });
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Directory',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
              onPressed: () => _loadBusinesses(context),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryFilters(),
            _buildResultsHeader(),
            Expanded(
              child: BlocBuilder<BusinessesCubit, BusinessesState>(
                builder: (context, state) {
                  if (state is BusinessesLoading) {
                    return const HabraCircularLoader(fullScreen: true);
                  }

                  if (state is BusinessesError) {
                    return _buildErrorView(state.message);
                  }

                  if (state is BusinessesLoaded) {
                    if (state.businesses.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildBusinessesList(state.businesses);
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
                      onChanged: (value) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 400),
                          () {
                            if (context.mounted) _loadBusinesses(context);
                          },
                        );
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _loadBusinesses(context);
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
      BusinessCategory.legal,
      BusinessCategory.coffee,
      BusinessCategory.spices,
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
                _loadBusinesses(context);
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

  Widget _buildResultsHeader() {
    return BlocBuilder<BusinessesCubit, BusinessesState>(
      builder: (context, state) {
        final count = state is BusinessesLoaded ? state.businesses.length : 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count Businesses found',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _currentLocation,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBusinessesList(List businesses) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadBusinesses(context);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: businesses.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BusinessListItemWidget(
              business: businesses[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BusinessDetailPage(businessId: businesses[index].id),
                  ),
                );
              },
            ),
          );
        },
      ),
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
            'Error loading businesses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadBusinesses(context),
            child: const Text('Retry'),
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
            Icons.store_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          const Text(
            'No businesses found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Try adjusting your filters or search query. New businesses may need admin approval before appearing.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
