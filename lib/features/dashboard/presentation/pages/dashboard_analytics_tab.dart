import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../widgets/empty_state_widget.dart';
import '../../../../core/resources/app_assets.dart';

class DashboardAnalyticsTab extends StatelessWidget {
  const DashboardAnalyticsTab({
    super.key,
    this.analytics,
    this.onQuickStatTap,
  });

  final DashboardAnalytics? analytics;
  final void Function(String type)? onQuickStatTap;

  @override
  Widget build(BuildContext context) {
    if (analytics == null) {
      return EmptyStateWidget(
        illustrationPath: AppAssets.dashboardNoAnalytics,
        title: 'No analytics yet',
        description: 'Start getting more visibility by posting deals and jobs. '
            'Your performance data will show here once you have activity.',
      );
    }

    final a = analytics!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppResources.spacingM, 8, AppResources.spacingM, 24),
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
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  value: a.totalViewsFormatted,
                  trend: a.viewsChangePercent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  value: a.clicksFormatted,
                  trend: a.clicksChangePercent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  value: a.messagesFormatted,
                  trend: a.messagesChangePercent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
            a.viewsOverTimeSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _ViewsChart(points: a.viewsOverTime),
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
            iconColor: AppColors.brandPrimary,
            title: '${a.activeJobsCount} Active Job',
            subtitle: a.activeJobTitle ?? 'Manage job posts',
            onTap: () => onQuickStatTap?.call('jobs'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.trend});

  final String value;
  final double trend;

  @override
  Widget build(BuildContext context) {
    final isNegative = trend < 0;
    final color = isNegative ? AppColors.error : AppColors.success;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      margin: EdgeInsets.zero,
      backgroundColor: AppColors.backgroundLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isNegative ? Icons.trending_down : Icons.trending_up,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                '${isNegative ? "" : "+"}${trend.round()}%',
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ViewsChart extends StatelessWidget {
  const _ViewsChart({required this.points});

  final List<DailyViewsPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox(height: 120);
    final maxV = points.map((e) => e.views).reduce((a, b) => a > b ? a : b);
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${points.fold<int>(0, (s, p) => s + p.views)} Total',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((p) {
                final h = maxV > 0 ? (p.views / maxV) * 80 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: h.clamp(4.0, 80.0),
                          decoration: BoxDecoration(
                            color: AppColors.brandSecondary.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.dayLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
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
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
