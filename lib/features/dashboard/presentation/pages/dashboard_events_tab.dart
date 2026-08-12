import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/business_owner_tool_route.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/owner_upcoming_event.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/legal_docs_required_banner.dart';
import '../widgets/payout_setup_required_banner.dart';
import '../../../events/presentation/bloc/create_event_cubit.dart';
import '../../../events/presentation/pages/create_event_page.dart';
import '../../../events/presentation/pages/scan_ticket_page.dart';
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../bloc/dashboard_cubit.dart';

/// Lists organizer events for the focused business: Active, Past, Draft.
class DashboardEventsTab extends StatefulWidget {
  const DashboardEventsTab({
    super.key,
    required this.events,
    required this.onCreateEvent,
    required this.showPayoutSetupBanner,
    required this.onSetUpPayouts,
    this.showLegalDocsBanner = false,
    this.legalDocsAwaitingReview = false,
    this.onUploadLegalDocs,
    this.connectStatus,
    this.onRefresh,
  });

  final List<OwnerUpcomingEvent> events;
  final VoidCallback onCreateEvent;
  final bool showPayoutSetupBanner;
  final VoidCallback onSetUpPayouts;
  final bool showLegalDocsBanner;
  final bool legalDocsAwaitingReview;
  final VoidCallback? onUploadLegalDocs;
  final String? connectStatus;
  final Future<void> Function()? onRefresh;

  @override
  State<DashboardEventsTab> createState() => _DashboardEventsTabState();
}

class _DashboardEventsTabState extends State<DashboardEventsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static String _formatStart(DateTime start) {
    final local = start.toLocal();
    return DateFormat('EEE, MMM d • h:mm a').format(local);
  }

  static String _formatEnd(DateTime end) {
    final local = end.toLocal();
    return DateFormat('MMM d, y • h:mm a').format(local);
  }

  List<OwnerUpcomingEvent> get _active {
    final list = widget.events.where((e) => e.isActiveListing).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return list;
  }

  List<OwnerUpcomingEvent> get _past {
    final list = widget.events.where((e) => e.isPast).toList()
      ..sort((a, b) => b.endAt.compareTo(a.endAt));
    return list;
  }

  List<OwnerUpcomingEvent> get _drafts {
    final list = widget.events.where((e) => e.isDraft).toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showLegalDocsBanner) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LegalDocsRequiredBanner(
            awaitingReview: widget.legalDocsAwaitingReview,
            onUploadDocuments: widget.onUploadLegalDocs,
          ),
          Expanded(
            child: widget.events.isEmpty
                ? _buildPrerequisiteEmptyHint(
                    title: widget.legalDocsAwaitingReview
                        ? 'Waiting for document approval'
                        : 'Legal documents needed first',
                    description: widget.legalDocsAwaitingReview
                        ? 'Once Habra approves your business license, you can set up payouts and create events.'
                        : 'Upload your business license before setting up payouts or creating events.',
                  )
                : _buildTabbedEvents(),
          ),
        ],
      );
    }

    if (widget.showPayoutSetupBanner) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PayoutSetupRequiredBanner(
            connectStatus: widget.connectStatus,
            onSetUpPayouts: widget.onSetUpPayouts,
          ),
          Expanded(
            child: widget.events.isEmpty
                ? _buildPrerequisiteEmptyHint(
                    title: 'Events will appear here',
                    description:
                        'After payout setup is complete, you can create events and sell tickets.',
                  )
                : _buildTabbedEvents(),
          ),
        ],
      );
    }

    if (widget.events.isEmpty) {
      return EmptyStateWidget(
        illustrationPath: AppAssets.eventPlaceholder,
        title: 'No events yet',
        description:
            'Create an event to sell tickets and grow your community. '
            'Events linked to this listing appear here.',
        actionLabel: 'Create event',
        onAction: widget.onCreateEvent,
      );
    }

    return _buildTabbedEvents();
  }

  Widget _buildPrerequisiteEmptyHint({
    required String title,
    required String description,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppResources.spacingM,
        32,
        AppResources.spacingM,
        100,
      ),
      children: [
        Icon(
          Icons.event_busy_outlined,
          size: 56,
          color: AppColors.textTertiary.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTabbedEvents() {
    final tabBar = Material(
      color: AppColors.backgroundWhite,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.brandPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.brandPrimary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: [
          Tab(text: 'Active (${_active.length})'),
          Tab(text: 'Past (${_past.length})'),
          Tab(text: 'Draft (${_drafts.length})'),
        ],
      ),
    );

    final body = TabBarView(
      controller: _tabController,
      children: [
        _maybeRefresh(_buildTabBody(
          events: _active,
          emptyTitle: 'No active events',
          emptyDescription:
              'Published events that haven\'t ended yet show here.',
          subtitleFor: (e) => _formatStart(e.startAt),
          showScanButton: true,
        )),
        _maybeRefresh(_buildTabBody(
          events: _past,
          emptyTitle: 'No past events',
          emptyDescription:
              'After an event ends, you\'ll find it in this tab.',
          subtitleFor: (e) => 'Ended ${_formatEnd(e.endAt)}',
        )),
        _maybeRefresh(_buildTabBody(
          events: _drafts,
          emptyTitle: 'No drafts',
          emptyDescription:
              'Unpublished events (not active) appear here when you save them as drafts.',
          subtitleFor: (e) => _formatStart(e.startAt),
          showDraftBadge: true,
        )),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tabBar,
        Expanded(child: body),
      ],
    );
  }

  Widget _maybeRefresh(Widget scrollableChild) {
    final onRefresh = widget.onRefresh;
    if (onRefresh == null) return scrollableChild;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: scrollableChild,
    );
  }

  Widget _buildTabBody({
    required List<OwnerUpcomingEvent> events,
    required String emptyTitle,
    required String emptyDescription,
    required String Function(OwnerUpcomingEvent e) subtitleFor,
    bool showDraftBadge = false,
    bool showScanButton = false,
  }) {
    if (events.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppResources.spacingM,
          48,
          AppResources.spacingM,
          100,
        ),
        children: [
          Icon(Icons.event_busy_outlined,
              size: 56, color: AppColors.textTertiary.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(
            emptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            emptyDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    final list = ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppResources.spacingM,
        12,
        AppResources.spacingM,
        100,
      ),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final e = events[index];
        return _EventRow(
          event: e,
          subtitle: subtitleFor(e),
          showDraftBadge: showDraftBadge,
          onRefresh: widget.onRefresh,
          showScanButton: showScanButton,
        );
      },
    );

    return list;
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.subtitle,
    required this.showDraftBadge,
    this.onRefresh,
    this.showScanButton = false,
  });

  final OwnerUpcomingEvent event;
  final String subtitle;
  final bool showDraftBadge;
  final Future<void> Function()? onRefresh;
  final bool showScanButton;

  static const double _thumb = 56;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCard(context),
        if (showScanButton) ...[
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScanTicketPage(
                  eventId: event.id,
                  eventTitle: event.title,
                ),
              ),
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: const Text('Scan tickets'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandPrimary,
              side: BorderSide(color: AppColors.brandPrimary.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppResources.radiusM)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final url = event.imageUrl?.trim() ?? '';
    final hasImage = url.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final dashboardCubit = context.read<DashboardCubit>();
          final homeCubit = context.read<BusinessOwnerHomeCubit>();
          final createEventCubit = di.sl<CreateEventCubit>();
          await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(
              builder: (_) => MultiBlocProvider(
                providers: businessOwnerToolRouteProviders(
                  context,
                  dashboard: dashboardCubit,
                  home: homeCubit,
                  createEvent: createEventCubit,
                ),
                child: CreateEventPage(editingEventId: event.id),
              ),
            ),
          );
          await onRefresh?.call();
        },
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppResources.radiusM),
            border: Border.all(
              color: AppColors.textTertiary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: _thumb,
                  height: _thumb,
                  child: hasImage
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderThumb(),
                        )
                      : _placeholderThumb(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDraftBadge)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textTertiary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Draft',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return ColoredBox(
      color: AppColors.brandPrimary.withValues(alpha: 0.12),
      child: Icon(
        Icons.event_rounded,
        color: AppColors.brandPrimary,
        size: 28,
      ),
    );
  }
}
