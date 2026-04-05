import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/boost_plan_target.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../boosts/presentation/pages/order_confirmation_page.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';

class BoostListingPage extends StatefulWidget {
  const BoostListingPage({
    super.key,
    this.boostType,
    this.selectedId,
    this.selectedTitle,
    this.dealImageUrl,
    this.dealMerchantName,
    this.dealExpiresInDays,
    this.jobEmployerName,
  });

  final String? boostType;
  final String? selectedId;
  final String? selectedTitle;
  final String? dealImageUrl;
  final String? dealMerchantName;
  final String? dealExpiresInDays;
  final String? jobEmployerName;

  @override
  State<BoostListingPage> createState() => _BoostListingPageState();
}

class _BoostListingPageState extends State<BoostListingPage> {
  String get _planTarget =>
      widget.boostType ?? BoostPlanTarget.businessListing;

  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadBoostPlans(targetType: _planTarget);
  }

  Future<void> _boostNow(String price) async {
    final ctx = context;
    LoaderHelper.show(ctx, message: 'Processing...');
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!ctx.mounted) return;
    LoaderHelper.hide(ctx);
    if (!ctx.mounted) return;
    if (widget.boostType != null) {
      Navigator.pushReplacement(
        ctx,
        MaterialPageRoute(
          builder: (_) => OrderConfirmationPage(
            dealTitle: widget.selectedTitle,
            merchantName: widget.dealMerchantName,
            dealImageUrl: widget.dealImageUrl,
            expiresInDays: widget.dealExpiresInDays,
            jobTitle: widget.selectedTitle,
            employerName: widget.jobEmployerName,
            listingTitle: widget.selectedTitle,
          ),
        ),
      );
    } else {
      Navigator.pop(ctx, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Boost Listing',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is BoostPlansLoading || state is DashboardInitial) {
            return const HabraCircularLoader(fullScreen: true);
          }
          if (state is DashboardError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppResources.spacingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go back'),
                        ),
                        const SizedBox(width: 16),
                        FilledButton(
                          onPressed: () => context
                              .read<DashboardCubit>()
                              .loadBoostPlans(targetType: _planTarget),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! BoostPlansLoaded) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppResources.spacingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No boost plans are available right now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              ),
            );
          }
          final plans = state.plans;
          if (plans.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppResources.spacingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No boost plans are available right now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              ),
            );
          }
          final selectedIndex = state.selectedIndex;
          final selected = plans[selectedIndex.clamp(0, plans.length - 1)];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppResources.spacingM),
            child: Column(
              children: [
                Image.asset(
                  AppAssets.dashboardBoostRocket,
                  height: 120,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.rocket_launch,
                    size: 80,
                    color: AppColors.brandSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Skyrocket Your Visibility',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Get seen by thousands of customers in the Habesha community today.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _BenefitCard(
                  icon: Icons.trending_up,
                  title: 'Top of Search',
                  description: 'Appear first in local search results',
                ),
                _BenefitCard(
                  icon: Icons.verified,
                  title: 'Featured Badge',
                  description: 'Stand out with a special badge',
                ),
                _BenefitCard(
                  icon: Icons.headset_mic_outlined,
                  title: 'Priority Support',
                  description: 'Get faster assistance from our team',
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Duration',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(plans.length, (index) {
                  final plan = plans[index];
                  final isSelected = index == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => context.read<DashboardCubit>().setBoostPlanSelected(index),
                      child: AppCard(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.all(16),
                        backgroundColor: isSelected
                            ? AppColors.brandPrimary.withValues(alpha: 0.08)
                            : AppColors.backgroundLight,
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              // ignore: deprecated_member_use
                              groupValue: selectedIndex,
                              // ignore: deprecated_member_use
                              onChanged: (_) =>
                                  context.read<DashboardCubit>().setBoostPlanSelected(index),
                              fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) return AppColors.brandPrimary;
                                return AppColors.textSecondary;
                              }),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    plan.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (plan.originalPriceFormatted != null)
                                    Text(
                                      plan.originalPriceFormatted!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textTertiary,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              plan.priceFormatted,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Boost Now • ${selected.priceFormatted}',
                  onPressed: () => _boostNow(selected.priceFormatted),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      'Secure payment via Stripe',
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.brandPrimary, size: 22),
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
                  description,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
