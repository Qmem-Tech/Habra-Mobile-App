import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../domain/entities/active_boost.dart';

/// Light green surface for LIVE badge and auto-renew panel (wireframe).
Color _boostAccentSurface(BuildContext context) {
  return AppColors.brandPrimary.withValues(alpha: 0.12);
}

class ActiveBoostCard extends StatelessWidget {
  const ActiveBoostCard({
    super.key,
    required this.boost,
    required this.onTap,
    required this.onAutoRenewChanged,
  });

  final ActiveBoost boost;
  final VoidCallback onTap;
  final ValueChanged<bool> onAutoRenewChanged;

  @override
  Widget build(BuildContext context) {
    final accent = _boostAccentSurface(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(),
                  Padding(
                    padding: const EdgeInsets.all(AppResources.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandPrimary,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius:
                                    BorderRadius.circular(AppResources.radiusXL),
                              ),
                              child: Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandPrimary,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          boost.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          boost.dateRangeText,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricColumn(
                                label: 'Views',
                                value: boost.views,
                                change: '+${boost.viewsChangePercent}%',
                              ),
                            ),
                            Expanded(
                              child: _MetricColumn(
                                label: 'Clicks',
                                value: boost.clicks,
                                change: '+${boost.clicksChangePercent}%',
                              ),
                            ),
                            Expanded(
                              child: _MetricColumn(
                                label: 'Calls',
                                value: boost.calls,
                                change: '+${boost.callsChangePercent}%',
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppResources.spacingM,
              0,
              AppResources.spacingM,
              AppResources.spacingM,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(AppResources.radiusM),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppResources.spacingM,
                  vertical: AppResources.spacingS,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Auto-renew Boost',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Renew automatically on ${_monthDay(boost.endDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: boost.autoRenew,
                      onChanged: onAutoRenewChanged,
                      activeThumbColor: AppColors.brandPrimary,
                      activeTrackColor:
                          AppColors.brandPrimary.withValues(alpha: 0.45),
                      inactiveThumbColor: AppColors.backgroundGrey,
                      inactiveTrackColor:
                          AppColors.textTertiary.withValues(alpha: 0.35),
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

  Widget _buildImage() {
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: boost.imageUrl.isEmpty
          ? Container(
              color: AppColors.backgroundLight,
              child: const Icon(
                Icons.storefront,
                size: 48,
                color: AppColors.textTertiary,
              ),
            )
          : Image.network(
              boost.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.backgroundLight,
                child: const Icon(
                  Icons.storefront,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
    );
  }

  static String _monthDay(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    required this.change,
  });

  final String label;
  final String value;
  final String change;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(Icons.trending_up, size: 14, color: AppColors.success),
            const SizedBox(width: 2),
            Text(
              change,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
