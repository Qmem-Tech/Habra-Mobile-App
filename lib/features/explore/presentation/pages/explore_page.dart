import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/main_nav_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../home/presentation/pages/notification_page.dart';
import '../../domain/entities/business_category.dart';
import '../../domain/entities/deal.dart';
import '../bloc/businesses_cubit.dart';
import '../bloc/businesses_state.dart';
import '../bloc/deals_cubit.dart';
import '../bloc/deals_state.dart';
import '../widgets/category_button.dart';
import '../widgets/business_card.dart';
import '../widgets/deal_card.dart';
import 'directory_page.dart';
import 'deals_page.dart';
import 'business_detail_page.dart';
import 'deal_detail_page.dart';

class ExplorePage extends StatefulWidget {
  final String? location;

  const ExplorePage({super.key, this.location});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  String? _currentLocation;
  // ignore: unused_field - used when filtering by category
  BusinessCategory _selectedCategory = BusinessCategory.all;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.location ?? 'Washington, D.C.';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData(BuildContext context) {
    // Data loading is handled in BlocProvider creation
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final cubit = di.sl<BusinessesCubit>();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              cubit.loadBusinesses(
                location: _currentLocation,
                featuredOnly: false,
              );
            });
            return cubit;
          },
        ),
        BlocProvider(
          create: (context) {
            final cubit = di.sl<DealsCubit>();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              cubit.loadDeals(location: _currentLocation);
            });
            return cubit;
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildCategoryFilters(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadData(context);
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeaturedBusinesses(),
                        _buildHotDeals(),
                        _buildAllBusinesses(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () {
              MainNavScope.maybeOf(context)?.scaffoldKey.currentState?.openDrawer();
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Navigate to location selection
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _currentLocation ?? 'Washington, D.C.',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationPage(userId: MainNavScope.maybeOf(context)?.userId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DirectoryPage()),
          );
        },
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
              Text(
                'Find business, event...',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [
      BusinessCategory.food,
      BusinessCategory.beauty,
      BusinessCategory.grocery,
      BusinessCategory.legal,
      BusinessCategory.coffee,
      BusinessCategory.spices,
    ];

    return SizedBox(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CategoryButton(
                    category: category,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DirectoryPage(
                            initialCategory: category,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBusinesses() {
    return BlocBuilder<BusinessesCubit, BusinessesState>(
      builder: (context, state) {
        if (state is BusinessesLoading) {
          return const SizedBox(
            height: 200,
            child: Center(child: HabraCircularLoader()),
          );
        }

        if (state is BusinessesLoaded) {
          final featured = state.businesses.where((b) => b.isFeatured).toList();
          if (featured.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Featured Businesses',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DirectoryPage()),
                        );
                      },
                      child: const Text(
                        'View All >',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: featured.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: BusinessCard(
                        business: featured[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BusinessDetailPage(
                                businessId: featured[index].id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHotDeals() {
    return BlocBuilder<DealsCubit, DealsState>(
      builder: (context, state) {
        if (state is DealsLoading) {
          return const SizedBox(
            height: 200,
            child: Center(child: HabraCircularLoader()),
          );
        }

        if (state is DealsLoaded) {
          final hotDeals = state.deals.where((d) => d.type == DealType.hotDeal).take(3).toList();
          if (hotDeals.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Hot Deals',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text('🔥', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DealsPage()),
                        );
                      },
                      child: const Text(
                        'View All >',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: hotDeals.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: DealCard(
                        deal: hotDeals[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DealDetailPage(dealId: hotDeals[index].id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAllBusinesses() {
    return BlocBuilder<BusinessesCubit, BusinessesState>(
      builder: (context, state) {
        if (state is BusinessesLoading) {
          return const SizedBox(
            height: 200,
            child: Center(child: HabraCircularLoader()),
          );
        }

        if (state is BusinessesLoaded) {
          final businesses = state.businesses.take(6).toList();
          if (businesses.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Businesses',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DirectoryPage()),
                        );
                      },
                      child: const Text(
                        'View All >',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: businesses.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: BusinessCard(
                        business: businesses[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BusinessDetailPage(
                                businessId: businesses[index].id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
