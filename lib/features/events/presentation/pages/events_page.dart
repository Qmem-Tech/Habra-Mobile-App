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
  final TextEditingController _searchController = TextEditingController();
  EventCategory _selectedCategory = EventCategory.all;
  EventFilters? _activeFilters;
  String? _currentLocation;
  List<EventListItem> _availableEvents = const [];

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.location ?? 'Washington, D.C.';
  }

  String _headerLocationLabel(BuildContext context) {
    return SessionDeviceLocationCubit.tryLabel(context) ??
        _currentLocation ??
        'Washington, D.C.';
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
    _loadEvents(context);
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

  String? _trimmedSearchQueryOrNull() {
    final q = _searchController.text.trim();
    return q.isEmpty ? null : q;
  }

  void _loadEvents(BuildContext context) {
    final effective = _effectiveFilters();
    context.read<EventsCubit>().loadEvents(
          location: _currentLocation,
          filters: effective,
          searchQuery: _trimmedSearchQueryOrNull(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final sessionCubit = SessionDeviceLocationCubit.maybeOf(context);
    final body = Scaffold(
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
                    _availableEvents = state.events;
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
    );

    final synced = sessionCubit == null
        ? body
        : BlocListener<SessionDeviceLocationCubit, SessionDeviceLocationState>(
            listenWhen: (prev, curr) => curr is SessionDeviceLocationReady,
            listener: (context, state) {
              if (state is SessionDeviceLocationReady) {
                setState(
                  () => _currentLocation = state.location.fullDisplayName,
                );
                _loadEvents(context);
              }
            },
            child: body,
          );

    return BlocProvider(
      create: (context) {
        final cubit = di.sl<EventsCubit>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final loc = SessionDeviceLocationCubit.tryLabel(context) ??
              _currentLocation ??
              'Washington, D.C.';
          cubit.loadEvents(
            location: loc,
            filters: _effectiveFilters(),
            searchQuery: _trimmedSearchQueryOrNull(),
          );
        });
        return cubit;
      },
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
                        _headerLocationLabel(context),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
              onTap: () async {
                final query = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (searchContext) => events_search.SearchPage(
                      initialQuery: _searchController.text,
                      availableEvents: _availableEvents,
                    ),
                  ),
                );
                if (!mounted) return;
                if (query == null) return;
                _searchController.text = query;
                _loadEvents(context);
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
                    Expanded(
                      child: Text(
                        _searchController.text.trim().isEmpty
                            ? 'Search events...'
                            : _searchController.text.trim(),
                        style: TextStyle(
                          fontSize: 15,
                          color: _searchController.text.trim().isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_searchController.text.trim().isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _loadEvents(context);
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
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
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                _loadEvents(context);
              },
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandPrimary
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.backgroundGrey.withValues(alpha: 0.55),
                  ),
                ),
                child: Text(
                  category.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
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
