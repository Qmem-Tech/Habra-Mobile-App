import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/main_nav_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notification_icon_with_badge.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../home/presentation/pages/notification_page.dart';
import '../../domain/entities/event_list_item.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/entities/event_filters.dart';
import '../bloc/events_cubit.dart';
import '../bloc/events_state.dart';
import '../widgets/event_list_card.dart';
import 'event_detail_page.dart';
import 'event_filters_page.dart';
import 'search_page.dart' as events_search;

class EventsPage extends StatefulWidget {
  final String? location;

  const EventsPage({super.key, this.location});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  static const bool _locationFilterOnHold = true;
  final TextEditingController _searchController = TextEditingController();
  EventCategory _selectedCategory = EventCategory.all;
  EventFilters? _activeFilters;
  String? _currentLocation;

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

  /// Merges the horizontal category chips into [EventFilters.eventTypes] for the API
  /// (chips were previously ignored — only sheet filters were sent).
  EventFilters? _effectiveFilters() {
    final sheet = _activeFilters;
    if (_selectedCategory != EventCategory.all) {
      final base = sheet ?? const EventFilters();
      return base.copyWith(eventTypes: [_selectedCategory]);
    }
    if (sheet == null || !sheet.hasActiveFilters) return null;
    return sheet;
  }

  void _loadEvents(BuildContext context) {
    context.read<EventsCubit>().loadEvents(
          location: _currentLocation,
          filters: _effectiveFilters(),
          searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = di.sl<EventsCubit>();
        // Load events after cubit is created
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cubit.loadEvents(
            location: _currentLocation,
            filters: _effectiveFilters(),
            searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
          );
        });
        return cubit;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildCategoryFilters(),
              Expanded(
                child: BlocBuilder<EventsCubit, EventsState>(
                  builder: (context, state) {
                    if (state is EventsLoading) {
                      return const HabraCircularLoader(fullScreen: true);
                    }

                    if (state is EventsError) {
                      return _buildErrorView(state.message);
                    }

                    if (state is EventsLoaded) {
                      if (state.events.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildEventsList(state.events);
                    }

                    return const SizedBox.shrink();
                  },
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
              onTap: _locationFilterOnHold
                  ? null
                  : () {
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
                      ),
                    ),
                    if (!_locationFilterOnHold)
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
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (searchContext) => events_search.SearchPage(
                      onSearch: (query) {
                        _searchController.text = query;
                        // State's [context] finds [EventsCubit] from this page.
                        _loadEvents(context);
                      },
                    ),
                  ),
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
                      'Search events...',
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
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textPrimary),
            onPressed: () async {
              final ctx = context;
              final filters = await Navigator.push<EventFilters>(
                ctx,
                MaterialPageRoute(
                  builder: (_) => EventFiltersPage(initialFilters: _activeFilters),
                ),
              );
              if (!ctx.mounted) return;
              if (filters != null) {
                setState(() {
                  _activeFilters = filters;
                });
              }
              if (!ctx.mounted) return;
              if (filters != null) {
                _loadEvents(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [
      EventCategory.all,
      EventCategory.concerts,
      EventCategory.parties,
      EventCategory.cultural,
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
              _loadEvents(context);
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

  Widget _buildEventsList(List<EventListItem> events) {
    return RefreshIndicator(
          onRefresh: () async {
            _loadEvents(context);
          },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return EventListCard(
            event: events[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailPage(eventId: events[index].id),
                ),
              );
            },
            onBookmark: () {
              // TODO: Implement bookmark
            },
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
          Text(
            'Error loading events',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadEvents(context),
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
            Icons.event_busy,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            'No events found',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Try adjusting your filters or search query',
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
