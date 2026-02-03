import 'package:equatable/equatable.dart';

/// Single day data point for views-over-time chart.
class DailyViewsPoint extends Equatable {
  final String dayLabel;
  final int views;

  const DailyViewsPoint({required this.dayLabel, required this.views});

  @override
  List<Object?> get props => [dayLabel, views];
}

/// Analytics data for dashboard (performance overview + views over time + quick stats).
class DashboardAnalytics extends Equatable {
  final String totalViewsFormatted;
  final double viewsChangePercent;
  final String clicksFormatted;
  final double clicksChangePercent;
  final String messagesFormatted;
  final double messagesChangePercent;
  final List<DailyViewsPoint> viewsOverTime;
  final String viewsOverTimeSubtitle;
  final double? rating;
  final int? reviewCount;
  final int activeDealsCount;
  final String? activeDealsExpiry;
  final int activeJobsCount;
  final String? activeJobTitle;

  const DashboardAnalytics({
    required this.totalViewsFormatted,
    required this.viewsChangePercent,
    required this.clicksFormatted,
    required this.clicksChangePercent,
    required this.messagesFormatted,
    required this.messagesChangePercent,
    required this.viewsOverTime,
    this.viewsOverTimeSubtitle = 'Past 7 days performance',
    this.rating,
    this.reviewCount,
    this.activeDealsCount = 0,
    this.activeDealsExpiry,
    this.activeJobsCount = 0,
    this.activeJobTitle,
  });

  @override
  List<Object?> get props => [
        totalViewsFormatted,
        viewsChangePercent,
        clicksFormatted,
        clicksChangePercent,
        messagesFormatted,
        messagesChangePercent,
        viewsOverTime,
        viewsOverTimeSubtitle,
        rating,
        reviewCount,
        activeDealsCount,
        activeDealsExpiry,
        activeJobsCount,
        activeJobTitle,
      ];
}
