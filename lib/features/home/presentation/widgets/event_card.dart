import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../saved_items/domain/entities/saved_item.dart';
import '../../../saved_items/domain/usecases/save_item_usecase.dart';
import '../../domain/entities/event.dart';
import '../../../../core/theme/app_colors.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onGetTicket;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onGetTicket,
  });

  static const double cardWidth = 256;
  static const double imageHeight = 120;

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _savedThisSession = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Container(
      width: EventCard.cardWidth,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: EventCard.imageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _DateChip(dateTime: event.dateTime),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: Icon(
                            _savedThisSession ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: _savedThisSession
                                ? const Color(0xFFE53935)
                                : AppColors.textSecondary,
                          ),
                          onPressed: () => _onHeartTap(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _locationLine(event),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDateTime(event.dateTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: FilledButton(
                        onPressed: widget.onGetTicket ?? widget.onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.customerHomePrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Get Ticket',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _locationLine(Event e) {
    final v = e.venue?.trim();
    final loc = e.location.trim();
    if (v != null && v.isNotEmpty && loc.isNotEmpty) return '$v · $loc';
    if (v != null && v.isNotEmpty) return v;
    if (loc.isNotEmpty) return loc;
    return 'Location TBA';
  }

  Future<void> _onHeartTap(BuildContext context) async {
    if (Supabase.instance.client.auth.currentUser == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save events')),
      );
      return;
    }
    final e = widget.event;
    final result = await di.sl<SaveItemUseCase>()(
      itemType: SavedItemType.event,
      referenceId: e.id,
      title: e.title,
      subtitle:
          '${DateFormat('EEE, MMM d').format(e.dateTime)} · ${DateFormat('h:mm a').format(e.dateTime)}',
      imageUrl: e.imageUrl.trim().isNotEmpty ? e.imageUrl : null,
    );
    if (!context.mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        setState(() => _savedThisSession = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event saved to your list')),
        );
      },
    );
  }

  Widget _buildImage() {
    final url = widget.event.imageUrl.trim();
    if (url.isEmpty) {
      return _imagePlaceholder();
    }
    return Image.network(
      url,
      height: EventCard.imageHeight,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: EventCard.imageHeight,
          color: AppColors.backgroundLight,
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: EventCard.imageHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.customerHomePrimary.withValues(alpha: 0.85),
            AppColors.brandPrimaryLight.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: const Icon(Icons.event, size: 56, color: Colors.white70),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final dateLine = DateFormat('EEE, MMM d, y').format(dateTime);
    final timeLine = DateFormat('h:mm a').format(dateTime);
    return '$dateLine · $timeLine';
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.dateTime});

  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMM').format(dateTime).toUpperCase();
    final day = dateTime.day.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            month,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            day,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
