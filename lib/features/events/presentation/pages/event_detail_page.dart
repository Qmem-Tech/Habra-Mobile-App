import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/navigation/main_navigation_wrapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_share.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../saved_items/domain/entities/saved_item.dart';
import '../../../saved_items/domain/usecases/save_item_usecase.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/event_detail.dart';
import '../bloc/events_cubit.dart';
import '../bloc/events_state.dart';
import '../widgets/event_list_card.dart';
import '../widgets/event_map_preview.dart';
import 'select_tickets_page.dart';
import 'package:intl/intl.dart';

/// Raw URL from API (may omit scheme). Used for display and launching.
String? _onlineDisplayUrl(EventDetail event) {
  final raw = (event.onlineUrl ?? event.address).trim();
  return raw.isEmpty ? null : raw;
}

Uri? _onlineLaunchUri(String displayUrl) {
  final t = displayUrl.trim();
  if (t.isEmpty) return null;
  final parsed = Uri.tryParse(t);
  if (parsed != null &&
      parsed.hasScheme &&
      (parsed.scheme == 'http' || parsed.scheme == 'https')) {
    return parsed;
  }
  final prefixed = Uri.tryParse('https://$t');
  if (prefixed != null && prefixed.host.isNotEmpty) return prefixed;
  return null;
}

class EventDetailPage extends StatelessWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<EventsCubit>()..loadEventDetail(eventId),
      child: Scaffold(
        body: BlocBuilder<EventsCubit, EventsState>(
          builder: (context, state) {
            if (state is EventDetailLoading) {
              return const HabraCircularLoader(fullScreen: true);
            }

            if (state is EventDetailError) {
              return _buildErrorView(context, state.message);
            }

            if (state is EventDetailLoaded) {
              return _buildContent(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EventDetailLoaded state) {
    final event = state.event;
    return CustomScrollView(
      slivers: [
        _buildAppBar(context, event),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventInfo(context, event),
              _buildAboutSection(event),
              _buildLocationSection(context, event),
              _buildPriceSection(context, event),
              if (state.similarEvents.isNotEmpty) _buildSimilarEvents(context, state.similarEvents),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, EventDetail event) {
    final imageUrl = event.imageUrl;
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: imageUrl.startsWith('assets/')
            ? Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.backgroundGrey,
                    child: const Icon(Icons.event, size: 64, color: AppColors.textSecondary),
                  );
                },
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.backgroundGrey,
                    child: const Icon(Icons.event, size: 64, color: AppColors.textSecondary),
                  );
                },
              ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha:0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha:0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white),
          ),
          onPressed: () {
            shareText(
              '${event.title}\n${event.venue}\n${event.fullAddress}',
              subject: event.title,
            );
          },
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandSecondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark, color: Colors.white),
          ),
          onPressed: () async {
            if (Supabase.instance.client.auth.currentUser == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sign in to save events')),
              );
              return;
            }
            final result = await di.sl<SaveItemUseCase>()(
              itemType: SavedItemType.event,
              referenceId: event.id,
              title: event.title,
              subtitle:
                  '${event.venue} · ${DateFormat('EEE, MMM d').format(event.startDate)}',
              imageUrl:
                  event.imageUrl.isNotEmpty ? event.imageUrl : null,
            );
            if (!context.mounted) return;
            result.fold(
              (f) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(f.message)),
              ),
              (_) => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event saved to your list')),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEventInfo(BuildContext context, event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.categoriesDisplay,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.brandSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.calendar_today,
            DateFormat('EEE, MMM d').format(event.startDate),
            '${DateFormat('h:mm a').format(event.startDate)} - ${DateFormat('h:mm a').format(event.endDate)}',
          ),
          const SizedBox(height: 16),
          if (event.isOnline)
            _buildOnlineVenueRow(context, event)
          else
            _buildInfoRow(
              Icons.location_on,
              event.venue,
              event.fullAddress,
            ),
        ],
      ),
    );
  }

  Widget _buildOnlineVenueRow(BuildContext context, EventDetail event) {
    final linkText = _onlineDisplayUrl(event) ?? 'Link not available';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.link_rounded, color: AppColors.brandPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.venue,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: linkText == 'Link not available'
                    ? null
                    : () => _showOnlineLinkBottomSheet(context, event),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          linkText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: linkText == 'Link not available'
                                ? AppColors.textSecondary
                                : AppColors.brandPrimary,
                            decoration: linkText == 'Link not available'
                                ? TextDecoration.none
                                : TextDecoration.underline,
                            decorationColor: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                      if (linkText != 'Link not available') ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                          color: AppColors.brandPrimary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showOnlineLinkBottomSheet(BuildContext context, EventDetail event) async {
    final displayUrl = _onlineDisplayUrl(event);
    if (displayUrl == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 8, 8),
                        child: Text(
                          'Online event link',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Tap below to open this URL in your browser (Zoom, Meet, etc.).',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SelectableText(
                    displayUrl,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: FilledButton.icon(
                    onPressed: () async {
                      await _openOnlineUrlInBrowser(sheetContext, displayUrl);
                    },
                    icon: const Icon(Icons.open_in_browser_rounded),
                    label: const Text('Open in browser'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openOnlineUrlInBrowser(BuildContext context, String displayUrl) async {
    final uri = _onlineLaunchUri(displayUrl);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This link could not be opened.')),
        );
      }
      return;
    }
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.brandPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(event) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Event',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            event.description,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context, EventDetail event) {
    if (event.isOnline) {
      final url = _onlineDisplayUrl(event);
      return Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Join online',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (url == null)
              Text(
                'No meeting link was provided for this event.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              )
            else
              Material(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showOnlineLinkBottomSheet(context, event),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.video_camera_front_outlined,
                          color: AppColors.brandPrimary,
                          size: 28,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meeting link',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                url,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.brandPrimary,
                                  height: 1.25,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          EventMapPreview(
            event: event,
            height: 200,
            showDirectionsButton: event.latitude != null && event.longitude != null,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context, event) {
    final price = event.minPrice != null
        ? '\$${event.minPrice!.toStringAsFixed(2)}'
        : 'Free';
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              AppButton(
                text: 'Get Tickets',
                width: 150,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SelectTicketsPage(eventId: event.id),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarEvents(BuildContext context, similarEvents) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'You Might Also Like',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  // Land the user back on the Events tab so they can browse more.
                  MainNavigationWrapper.navigateToTab(context, 1);
                },
                child: Text(
                  'View All >',
                  style: TextStyle(color: AppColors.brandPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: similarEvents.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == similarEvents.length - 1 ? 0 : 16,
                  ),
                  child: SizedBox(
                    width: 280,
                    child: EventListCard(
                      event: similarEvents[index],
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailPage(eventId: similarEvents[index].id),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Error loading event',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
