import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../bloc/boosts_cubit.dart';
import '../bloc/boosts_state.dart';
import 'cancel_boost_sheet.dart';

class ActiveBoostDetailsPage extends StatefulWidget {
  const ActiveBoostDetailsPage({super.key, required this.boostId});

  final String boostId;

  @override
  State<ActiveBoostDetailsPage> createState() => _ActiveBoostDetailsPageState();
}

class _ActiveBoostDetailsPageState extends State<ActiveBoostDetailsPage> {
  @override
  void initState() {
    super.initState();
    context.read<BoostsCubit>().loadActiveBoostDetail(widget.boostId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Active Boost Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<BoostsCubit, BoostsState>(
        builder: (context, state) {
          if (state is BoostsLoading || state is BoostsInitial) {
            return const HabraCircularLoader(fullScreen: true);
          }
          if (state is BoostsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppResources.spacingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! ActiveBoostDetailLoaded) {
            return const SizedBox.shrink();
          }
          final boost = state.boost;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppResources.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Listing Boost',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildListingCard(boost),
                const SizedBox(height: 24),
                _buildDurationCard(boost),
                const SizedBox(height: 24),
                const Text(
                  'Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPerformanceGrid(boost),
                const SizedBox(height: 24),
                _buildAutoRenewCard(boost),
                const SizedBox(height: 24),
                _buildCancelButton(context, boost.id),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListingCard(boost) {
    return Container(
      decoration: BoxDecoration(
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
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Image.network(
              boost.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.backgroundLight,
                child: const Icon(Icons.storefront, size: 48, color: AppColors.textTertiary),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppResources.spacingM),
            color: AppColors.backgroundWhite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boost.typeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        boost.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppResources.radiusS),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  boost.dateRangeText,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (boost.planLabel != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                    ),
                    child: Text(
                      boost.planLabel!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard(boost) {
    final remaining = boost.remainingDays;
    final total = boost.endDate.difference(boost.startDate).inDays;
    final elapsed = total - remaining;
    final progress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Duration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppResources.radiusS),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Started ${_formatMonthDay(boost.startDate)}',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                'Ends ${_formatMonthDay(boost.endDate)}',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.progressInactive,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: AppColors.brandPrimary),
              const SizedBox(width: 4),
              Text(
                '$remaining days remaining',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceGrid(boost) {
    final items = [
      ('Total Views', boost.views, '${boost.viewsChangePercent}% vs last mo', true),
      ('Total Clicks', boost.clicks, '${boost.clicksChangePercent}% vs last mo', true),
      ('Calls', boost.calls, '${boost.callsChangePercent}% vs last mo', true),
      ('Saves', boost.saves ?? '0', boost.savesChangePercent != null && boost.savesChangePercent == 0 ? 'No change' : '${boost.savesChangePercent ?? 0}% vs last mo', boost.savesChangePercent != 0),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        for (final item in items) _performanceCard(item.$1, item.$2, item.$3, item.$4),
      ],
    );
  }

  Widget _performanceCard(String label, String value, String change, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (isPositive)
                Icon(Icons.trending_up, size: 12, color: AppColors.success),
              if (isPositive) const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  color: isPositive ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoRenewCard(boost) {
    return Container(
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-Renewal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Renews on Feb 2 for',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: boost.autoRenew,
            onChanged: (v) async {
              LoaderHelper.show(context, message: 'Updating...');
              final cubit = context.read<BoostsCubit>();
              await cubit.setAutoRenew(boost.id, v);
              if (!mounted) return;
              LoaderHelper.hide(context);
              cubit.loadActiveBoostDetail(boost.id);
            },
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.brandPrimary
                  : AppColors.backgroundGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, String boostId) {
    return TextButton(
      onPressed: () => _showCancelSheet(context, boostId),
      child: const Text(
        'CANCEL BOOST',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.brandPrimary,
        ),
      ),
    );
  }

  Future<void> _showCancelSheet(BuildContext context, String boostId) async {
    final cancelled = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancelBoostSheet(
        boostId: boostId,
        listingName: 'Abyssinia Restaurant',
        listingSubtitle: 'Ethiopian Cuisine • WB',
        listingImageUrl: null,
        onCancelBoost: () async {
          if (!context.mounted) return;
          LoaderHelper.show(context, message: 'Cancelling...');
          final cubit = context.read<BoostsCubit>();
          await cubit.cancelBoost(boostId);
          if (!context.mounted) return;
          LoaderHelper.hide(context);
          Navigator.pop(context, true);
        },
      ),
    );
    if (cancelled == true && context.mounted) {
      Navigator.pop(context);
    }
  }

  static String _formatMonthDay(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}
