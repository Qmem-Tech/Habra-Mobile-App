import 'package:flutter/material.dart';
import '../../domain/entities/event.dart';
import '../../../../core/theme/app_colors.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  static const double _cardWidth = 300;
  static const double _imageHeight = 232;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _cardWidth,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImage(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.25,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 17,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatDateTime(event.dateTime),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = event.imageUrl.trim();
    if (url.isEmpty) {
      return _imagePlaceholder();
    }
    return Image.network(
      url,
      height: _imageHeight,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: _imageHeight,
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
      height: _imageHeight,
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
    final weekday = _getWeekday(dateTime.weekday);
    final time = _formatTime(dateTime);
    return '$weekday, $time';
  }

  String _getWeekday(int weekday) {
    // DateTime.weekday: Monday = 1 … Sunday = 7
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday < 1 || weekday > 7) return '';
    return weekdays[weekday - 1];
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : hour;
    return '$displayHour:$minute $amPm';
  }
}
