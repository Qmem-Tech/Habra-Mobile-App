import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/location/profile_home_city_sync.dart';
import '../../../../core/location/session_device_location_cubit.dart';
import '../../../../core/navigation/main_nav_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notification_icon_with_badge.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../home/domain/entities/location_entity.dart';
import '../../../home/presentation/pages/location_selection_page.dart';
import '../../../home/presentation/pages/notification_page.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/listing_category.dart';
import '../../domain/usecases/get_active_listing_categories_usecase.dart';
import '../bloc/businesses_cubit.dart';
import '../bloc/businesses_state.dart';
import '../bloc/deals_cubit.dart';
import '../bloc/deals_state.dart';
import '../widgets/business_card.dart';
import '../widgets/listing_category_icon.dart';
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
  String? _selectedListingCategoryId;
  List<ListingCategory> _listingCategories = [];
  bool _listingCategoriesLoading = true;
  bool _initialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.location;
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

  /// Opens directory; respects last tapped category chip (not just "All").
  void _openDirectory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DirectoryPage(
          initialListingCategoryId: _selectedListingCategoryId,
        ),
      ),
    );
  }

  static const _kUnsetLocation = 'Choose your location';

  String _resolvedLocationLabel(BuildContext context) {
    return SessionDeviceLocationCubit.tryLabel(context) ??
        (_currentLocation?.trim().isNotEmpty == true
            ? _currentLocation!
            : _kUnsetLocation);
  }

  Future<void> _loadData(BuildContext context) async {
    if (!context.mounted) return;
    final sessionLoc = SessionDeviceLocationCubit.tryLabel(context);
    final stored =
        _currentLocation?.trim().isNotEmpty == true ? _currentLocation : null;
    final loc = sessionLoc ?? stored;
    await context.read<BusinessesCubit>().loadBusinesses(
          location: loc,
          featuredOnly: false,
          userGeo: SessionDeviceLocationCubit.tryGeo(context),
        );
    if (!context.mounted) return;
    await context.read<DealsCubit>().loadDeals(location: loc);
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LocationEntity>(
      context,
      MaterialPageRoute(builder: (_) => const LocationSelectionPage()),
    );
    if (!mounted || result == null) return;
    SessionDeviceLocationCubit.maybeOf(context)?.setSessionLocation(result);
    setState(() => _currentLocation = result.fullDisplayName);
    await persistProfileHomeCityIfSignedIn(context, result);
    if (!mounted) return;
    _loadData(context);
  }

  @override
  Widget build(BuildContext context) {
    final sessionCubit = SessionDeviceLocationCubit.maybeOf(context);
    final scaffold = Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryFilters(),
            Expanded(child: _buildMainContent()),
          ],
        ),
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
                _loadData(context);
              }
            },
            child: scaffold,
          );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final cubit = di.sl<BusinessesCubit>();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final sessionLoc = SessionDeviceLocationCubit.tryLabel(context);
              final stored = _currentLocation?.trim().isNotEmpty == true
                  ? _currentLocation
                  : null;
              cubit.loadBusinesses(
                location: sessionLoc ?? stored,
                featuredOnly: false,
                userGeo: SessionDeviceLocationCubit.tryGeo(context),
              );
            });
            return cubit;
          },
        ),
        BlocProvider(
          create: (context) {
            final cubit = di.sl<DealsCubit>();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final sessionLoc = SessionDeviceLocationCubit.tryLabel(context);
              final stored = _currentLocation?.trim().isNotEmpty == true
                  ? _currentLocation
                  : null;
              cubit.loadDeals(location: sessionLoc ?? stored);
            });
            return cubit;
          },
        ),
      ],
      child: synced,
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
              onTap: _openLocationPicker,
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
                        _resolvedLocationLabel(context),
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
          NotificationIconWithBadge(
            userId: MainNavScope.maybeOf(context)?.userId,
            onOpenNotifications: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
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
        onTap: () => _openDirectory(context),
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

  bool _isInitialExploreLoading(BusinessesState businesses, DealsState deals) {
    if (_initialLoadComplete) return false;
    if (_listingCategoriesLoading) return true;
    if (businesses is BusinessesInitial || businesses is BusinessesLoading) {
      return true;
    }
    if (deals is DealsInitial || deals is DealsLoading) return true;
    return false;
  }

  void _markInitialLoadCompleteIfReady(
    BusinessesState businesses,
    DealsState deals,
  ) {
    if (_initialLoadComplete || _listingCategoriesLoading) return;
    if (businesses is BusinessesInitial || businesses is BusinessesLoading) {
      return;
    }
    if (deals is DealsInitial || deals is DealsLoading) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _initialLoadComplete = true);
    });
  }

  Widget _buildMainContent() {
    return BlocBuilder<BusinessesCubit, BusinessesState>(
      builder: (context, businessState) {
        return BlocBuilder<DealsCubit, DealsState>(
          builder: (context, dealsState) {
            _markInitialLoadCompleteIfReady(businessState, dealsState);
            final showLoader =
                _isInitialExploreLoading(businessState, dealsState);

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => _loadData(context),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!showLoader) ...[
                          _buildFeaturedBusinesses(businessState),
                          _buildHotDeals(dealsState),
                          _buildAllBusinesses(businessState),
                        ] else
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.45,
                          ),
                      ],
                    ),
                  ),
                ),
                if (showLoader)
                  const HabraCircularLoader(fullScreen: true),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryFilters() {
    if (_listingCategoriesLoading && !_initialLoadComplete) {
      return const SizedBox(height: 128);
    }
    if (_listingCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _listingCategories.length,
            itemBuilder: (context, index) {
              final category = _listingCategories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedListingCategoryId = category.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DirectoryPage(
                          initialListingCategoryId: category.id,
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 80,
                    height: 88,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            listingCategoryIcon(category.iconKey),
                            size: 28,
                            color: AppColors.brandPrimary,
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedBusinesses(BusinessesState state) {
    if (state is BusinessesLoaded) {
          final featured = [...state.businesses]
            ..sort((a, b) {
              if (b.rating != a.rating) return b.rating.compareTo(a.rating);
              return b.reviewCount.compareTo(a.reviewCount);
            });
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
                      onTap: () => _openDirectory(context),
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
                height: 230,
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
  }

  Widget _buildHotDeals(DealsState state) {
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
  }

  Widget _buildAllBusinesses(BusinessesState state) {
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
                      onTap: () => _openDirectory(context),
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
                height: 230,
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
              const SizedBox(height: 12),
            ],
          );
    }

    return const SizedBox.shrink();
  }
}
