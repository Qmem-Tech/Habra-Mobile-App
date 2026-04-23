import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/resources/app_assets.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../widgets/empty_state_widget.dart';

/// Purple accent for Jobs quick stat (design mock).
const Color _jobsQuickStatPurple = Color(0xFF7E57C2);

class DashboardAnalyticsTab extends StatelessWidget {
  const DashboardAnalyticsTab({
    super.key,
    this.analytics,
    this.analyticsLocked = false,
    this.onQuickStatTap,
    this.onRefresh,
  });

  final DashboardAnalytics? analytics;
  final bool analyticsLocked;
  final void Function(String type)? onQuickStatTap;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (analyticsLocked) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppResources.spacingM,
          12,
          AppResources.spacingM,
          24,
        ),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Analytics is available on Pro and Premium.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Upgrade your business plan to unlock views trends, quick stats, and performance insights.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (analytics == null) {
      return EmptyStateWidget(
        illustrationPath: AppAssets.dashboardNoAnalytics,
        title: 'No analytics yet',
        description: 'Start getting more visibility by posting deals and jobs. '
            'Your performance data will show here once you have activity.',
      );
    }

    final a = analytics!;
    final scrollView = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 12, AppResources.spacingM, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _MetricCard(
            label: 'Total Views',
            value: a.totalViewsFormatted,
            trend: a.viewsChangePercent,
          ),
          const SizedBox(height: 24),
          _ViewsOverTimeSection(
            subtitle: a.viewsOverTimeSubtitle,
            points: a.viewsOverTime,
            fallbackTotalLabel: a.totalViewsFormatted,
          ),
          const SizedBox(height: 24),
          const Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _QuickStatTile(
            icon: Icons.star,
            iconColor: AppColors.brandSecondary,
            title: '${a.rating ?? 0} Rating',
            subtitle: 'Based on ${a.reviewCount ?? 0} reviews',
            onTap: () => onQuickStatTap?.call('reviews'),
          ),
          _QuickStatTile(
            icon: Icons.sell,
            iconColor: AppColors.info,
            title: '${a.activeDealsCount} Active Deals',
            subtitle: a.activeDealsExpiry ?? 'Manage your deals',
            onTap: () => onQuickStatTap?.call('deals'),
          ),
          _QuickStatTile(
            icon: Icons.work_outline,
            iconColor: _jobsQuickStatPurple,
            title: '${a.activeJobsCount} Active Job',
            subtitle: a.activeJobTitle ?? 'Manage job posts',
            onTap: () => onQuickStatTap?.call('jobs'),
          ),
        ],
      ),
    );
    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: scrollView,
      );
    }
    return scrollView;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.trend,
  });

  final String label;
  final String value;
  final double trend;

  @override
  Widget build(BuildContext context) {
    final isNegative = trend < 0;
    final trendColor = isNegative ? AppColors.error : AppColors.success;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      margin: EdgeInsets.zero,
      backgroundColor: AppColors.backgroundWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNegative ? Icons.trending_down : Icons.trending_up,
                  size: 14,
                  color: trendColor,
                ),
                const SizedBox(width: 2),
                Text(
                  '${isNegative ? '' : '+'}${trend.round()}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: trendColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewsOverTimeSection extends StatelessWidget {
  const _ViewsOverTimeSection({
    required this.subtitle,
    required this.points,
    required this.fallbackTotalLabel,
  });

  final String subtitle;
  final List<DailyViewsPoint> points;
  final String fallbackTotalLabel;

  int get _periodTotal => points.fold<int>(0, (s, p) => s + p.views);

  bool get _hasPlottableData =>
      points.isNotEmpty && points.any((p) => p.views > 0);

  String get _totalDisplay {
    if (points.isEmpty) return fallbackTotalLabel;
    return NumberFormat('#,###').format(_periodTotal);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Views Over Time',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$_totalDisplay Total',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.brandSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_hasPlottableData)
          _ViewsLineChartCard(points: points)
        else
          _ViewsChartEmptyCard(
            pointsEmpty: points.isEmpty,
          ),
      ],
    );
  }
}

class _ViewsChartEmptyCard extends StatelessWidget {
  const _ViewsChartEmptyCard({required this.pointsEmpty});

  final bool pointsEmpty;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      backgroundColor: AppColors.backgroundWhite,
      child: Column(
        children: [
          Icon(
            pointsEmpty ? Icons.show_chart : Icons.insights_outlined,
            size: 40,
            color: AppColors.brandSecondary.withValues(alpha: 0.65),
          ),
          const SizedBox(height: 12),
          Text(
            pointsEmpty
                ? 'No view data for this period'
                : 'No views recorded this week',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pointsEmpty
                ? 'Daily breakdown will appear here once analytics are connected. '
                    'Performance metrics above still reflect your listing.'
                : 'When customers view your listing, you will see the trend here.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewsLineChartCard extends StatelessWidget {
  const _ViewsLineChartCard({required this.points});

  final List<DailyViewsPoint> points;

  int get _peakIndex {
    var maxV = -1;
    var idx = 0;
    for (var i = 0; i < points.length; i++) {
      if (points[i].views > maxV) {
        maxV = points[i].views;
        idx = i;
      }
    }
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    final peak = _peakIndex;
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      backgroundColor: AppColors.backgroundWhite,
      child: Column(
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _ViewsLineChartPainter(
                points: points,
                lineColor: AppColors.brandSecondary,
                highlightIndex: peak,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: points.map((p) {
              return Expanded(
                child: Text(
                  p.dayLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ViewsLineChartPainter extends CustomPainter {
  _ViewsLineChartPainter({
    required this.points,
    required this.lineColor,
    required this.highlightIndex,
  });

  final List<DailyViewsPoint> points;
  final Color lineColor;
  final int highlightIndex;

  static void _dashLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashLen = 4.0;
    const gapLen = 5.0;
    final d = b - a;
    final len = d.distance;
    if (len < 0.001) return;
    final dir = d / len;
    var dist = 0.0;
    var draw = true;
    while (dist < len) {
      final seg = draw ? dashLen : gapLen;
      final end = math.min(dist + seg, len);
      if (draw) {
        canvas.drawLine(a + dir * dist, a + dir * end, paint);
      }
      dist = end;
      draw = !draw;
    }
  }

  List<Offset> _offsets(Size size) {
    final maxV = points.map((e) => e.views).reduce(math.max).toDouble();
    final range = maxV <= 0 ? 1.0 : maxV;
    const padX = 8.0;
    const padTop = 12.0;
    const padBottom = 4.0;
    final chartH = size.height - padTop - padBottom;
    final chartW = size.width - 2 * padX;
    final n = points.length;
    if (n == 0) return [];
    return List.generate(n, (i) {
      final x = padX + chartW * (n == 1 ? 0.5 : i / (n - 1));
      final y = padTop + chartH * (1 - points[i].views / range);
      return Offset(x, y);
    });
  }

  Path _smoothLinePath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    if (pts.length == 1) {
      path.moveTo(pts.first.dx, pts.first.dy);
      return path;
    }
    path.moveTo(pts.first.dx, pts.first.dy);
    const tension = 0.25;
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i > 0 ? pts[i - 1] : pts[i];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i < pts.length - 2 ? pts[i + 2] : p2;
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) * tension,
        p1.dy + (p2.dy - p0.dy) * tension,
        p2.dx - (p3.dx - p1.dx) * tension,
        p2.dy - (p3.dy - p1.dy) * tension,
        p2.dx,
        p2.dy,
      );
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final gridPaint = Paint()
      ..color = AppColors.textTertiary.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      _dashLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final offsets = _offsets(size);
    if (offsets.isEmpty) return;

    final baseY = size.height - 2;
    final fillPath = _smoothLinePath(offsets);
    fillPath.lineTo(offsets.last.dx, baseY);
    fillPath.lineTo(offsets.first.dx, baseY);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          lineColor.withValues(alpha: 0.28),
          lineColor.withValues(alpha: 0.02),
        ],
      );
    canvas.drawPath(fillPath, fillPaint);

    final linePath = _smoothLinePath(offsets);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (highlightIndex >= 0 && highlightIndex < offsets.length) {
      final hx = offsets[highlightIndex].dx;
      final hy = offsets[highlightIndex].dy;
      canvas.drawLine(
        Offset(hx, 8),
        Offset(hx, baseY),
        Paint()
          ..color = lineColor.withValues(alpha: 0.45)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(
        Offset(hx, hy),
        6,
        Paint()
          ..color = AppColors.backgroundWhite
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(hx, hy),
        6,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ViewsLineChartPainter oldDelegate) {
    return !listEquals(oldDelegate.points, points) ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.highlightIndex != highlightIndex;
  }
}

class _QuickStatTile extends StatelessWidget {
  const _QuickStatTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 22, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
