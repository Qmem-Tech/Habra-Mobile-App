import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/location/session_device_location_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/business_filters.dart';
import '../../domain/entities/listing_category.dart';
import '../../domain/usecases/get_active_listing_categories_usecase.dart';
import '../bloc/businesses_cubit.dart';
import '../bloc/businesses_state.dart';
import '../widgets/business_list_item_widget.dart';
import 'business_detail_page.dart';

class DirectoryPage extends StatefulWidget {
  /// `categories.id` from Supabase, or null for “all”.
  final String? initialListingCategoryId;

  const DirectoryPage({super.key, this.initialListingCategoryId});

  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  final TextEditingController _searchController = TextEditingController();
  BusinessesCubit? _businessesCubit;
  String? _selectedListingCategoryId;
  List<ListingCategory> _listingCategories = [];
  bool _categoriesLoading = true;
  String _currentLocation = 'Washington, D.C.';
  Timer? _searchDebounce;

  BusinessesCubit get _cubit => _businessesCubit ??= di.sl<BusinessesCubit>();

  @override
  void initState() {
    super.initState();
    _selectedListingCategoryId = widget.initialListingCategoryId;
    _loadCategoryRows();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadBusinesses(context);
    });
  }

  Future<void> _loadCategoryRows() async {
    final result = await di.sl<GetActiveListingCategoriesUseCase>()();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _categoriesLoading = false),
      (list) => setState(() {
        _listingCategories = list;
        _categoriesLoading = false;
      }),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _businessesCubit?.close();
    super.dispose();
  }

  void _loadBusinesses(BuildContext context) {
    final cid = _selectedListingCategoryId;
    final filters = (cid != null && cid.isNotEmpty)
        ? BusinessFilters(listingCategoryId: cid)
        : null;
    final loc = SessionDeviceLocationCubit.tryLabel(context) ??
        _currentLocation;
    _cubit.loadBusinesses(
      location: loc,
      filters: filters,
      searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
    );
  }

  String _displayLocationLabel(BuildContext context) {
    return SessionDeviceLocationCubit.tryLabel(context) ?? _currentLocation;
  }

  @override
  Widget build(BuildContext context) {
    final sessionCubit = SessionDeviceLocationCubit.maybeOf(context);
    final scaffold = Scaffold(
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
              bloc: _cubit,
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
                _loadBusinesses(context);
              }
            },
            child: scaffold,
          );

    return BlocProvider.value(
      value: _cubit,
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
                      onChanged: (value) {
                        setState(() {});
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
                        _searchDebounce?.cancel();
                        _searchController.clear();
                        setState(() {});
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
    if (_categoriesLoading) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          _directoryCategoryChip(label: 'All', id: null),
          ..._listingCategories.map(
            (c) => _directoryCategoryChip(label: c.name, id: c.id),
          ),
        ],
      ),
    );
  }

  Widget _directoryCategoryChip({required String label, required String? id}) {
    final isSelected = _selectedListingCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedListingCategoryId = id);
          _loadBusinesses(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandPrimary : Colors.white,
            borderRadius: BorderRadius.circular(18),
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

  Widget _buildResultsHeader() {
    return BlocBuilder<BusinessesCubit, BusinessesState>(
      bloc: _cubit,
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
                _displayLocationLabel(context),
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
