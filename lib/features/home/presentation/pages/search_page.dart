import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/repositories/search_repository.dart';
import '../bloc/search_cubit.dart';
import '../bloc/search_state.dart';
import 'search_results_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  SearchCategory _selectedCategory = SearchCategory.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Find business, event...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {});
            if (value.isEmpty) {
              context.read<SearchCubit>().search('', _selectedCategory, '');
            }
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _performSearch(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state is SearchResultsLoaded) {
            return SearchResultsPage(
              results: state.results,
              query: state.query,
              category: state.category,
            );
          }

          return _buildSearchInitialView(state);
        },
      ),
    );
  }

  Widget _buildSearchInitialView(SearchState state) {
    final recentSearches = state.recentSearches;
    final trendingSearches = state.trendingSearches;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryFilters(state),
          const SizedBox(height: 24),
          if (recentSearches.isNotEmpty) _buildRecentSearches(recentSearches, state),
          if (trendingSearches.isNotEmpty) _buildTrendingSearches(trendingSearches),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(SearchState state) {
    return Row(
      children: [
        _buildCategoryFilter(SearchCategory.all, 'All', state.selectedCategory),
        const SizedBox(width: 8),
        _buildCategoryFilter(SearchCategory.events, 'Events', state.selectedCategory),
        const SizedBox(width: 8),
        _buildCategoryFilter(SearchCategory.business, 'Business', state.selectedCategory),
        const SizedBox(width: 8),
        _buildCategoryFilter(SearchCategory.jobs, 'Jobs', state.selectedCategory),
      ],
    );
  }

  Widget _buildCategoryFilter(SearchCategory category, String label, SearchCategory selected) {
    final isSelected = category == selected;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        context.read<SearchCubit>().setCategory(category);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }

  Widget _buildRecentSearches(List<String> searches, SearchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.read<SearchCubit>().clearRecentSearches(),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...searches.map((search) => _buildSearchItem(search, isRecent: true)),
      ],
    );
  }

  Widget _buildTrendingSearches(List<String> searches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            const Text(
              'Trending Now',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.trending_up,
              size: 20,
              color: AppColors.brandPrimary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: searches.map((search) => _buildTrendingChip(search)).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchItem(String search, {required bool isRecent}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: Row(
        children: [
          Icon(
            isRecent ? Icons.history : Icons.search,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _searchController.text = search;
                _performSearch(search);
              },
              child: Text(
                search,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (isRecent)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: AppColors.textSecondary,
              onPressed: () {
                // TODO: Remove individual search
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTrendingChip(String search) {
    return GestureDetector(
      onTap: () {
        _searchController.text = search;
        _performSearch(search);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.backgroundGrey),
        ),
        child: Text(
          search,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      context.read<SearchCubit>().search(query, _selectedCategory, ''); // TODO: Pass location
    }
  }
}
