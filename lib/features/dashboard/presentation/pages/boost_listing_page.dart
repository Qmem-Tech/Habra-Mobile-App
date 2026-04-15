import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/boost_plan_target.dart';
import '../../../../core/services/revenue_cat_service.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../injection/injection_container.dart';
import '../../../boosts/domain/repositories/boosts_repository.dart';
import '../../../boosts/presentation/pages/order_confirmation_page.dart';
import '../../domain/entities/boost_plan.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';
import '../utils/boost_plan_display.dart';

class BoostListingPage extends StatefulWidget {
  const BoostListingPage({
    super.key,
    this.boostType,
    this.boostBusinessId,
    this.selectedId,
    this.selectedTitle,
    this.dealImageUrl,
    this.dealMerchantName,
    this.dealExpiresInDays,
    this.jobEmployerName,
  });

  final String? boostType;
  /// Owning business UUID for `boosts.business_id` (deal/job). If null, [selectedId] is used (listing).
  final String? boostBusinessId;
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

  /// Resolves `boosts.business_id` for Supabase (listing: selected business; deal/job: owning business).
  String? get _businessIdForBoost =>
      widget.boostBusinessId ?? widget.selectedId;

  bool _autoRenew = false;

  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadBoostPlans(targetType: _planTarget);
  }

  Future<void> _boostNow(BoostPlan plan) async {
    final businessId = _businessIdForBoost;
    if (businessId == null || businessId.isEmpty) {
      if (!mounted) return;
      _showBoostSubmitErrorDialog(
        title: 'Missing business',
        message:
            'We need a business id to create the boost. Open Boost from the '
            'wizard (pick a location, deal, or job) instead of this shortcut '
            'without a selection.',
      );
      return;
    }

    final optionType = _planTarget;
    final selectedId = widget.selectedId;
    final effectiveSelectedId = optionType == BoostPlanTarget.businessListing
        ? (selectedId ?? businessId)
        : selectedId;
    if (effectiveSelectedId == null || effectiveSelectedId.isEmpty) {
      if (!mounted) return;
      _showBoostSubmitErrorDialog(
        title: 'Missing selection',
        message: 'No deal, job, or listing id was passed to this screen.',
      );
      return;
    }

    final rc = sl<RevenueCatService>();
    if (!rc.isInitialized) {
      if (!mounted) return;
      _showBoostSubmitErrorDialog(
        title: 'Billing unavailable',
        message:
            'In-app purchases are not configured (RevenueCat API keys). '
            'Add REVENUECAT_ANDROID_API_KEY / REVENUECAT_IOS_API_KEY to your build.',
      );
      return;
    }

    final storeProductId = plan.billingProductId?.trim();
    if (storeProductId == null || storeProductId.isEmpty) {
      if (!mounted) return;
      _showBoostSubmitErrorDialog(
        title: 'Plan not linked to the store',
        message:
            'This boost plan is missing billing_product_id in Supabase (Table boost_plans). '
            'Set it to your App Store / Play product id so it matches RevenueCat.',
      );
      return;
    }

    final ctx = context;
    LoaderHelper.show(ctx, message: 'Processing payment…');
    final offeringId = AppConfig.revenueCatBoostOfferingId.trim();
    final package = await rc.findPackageByStoreProductId(
      storeProductId,
      offeringIdentifier: offeringId.isEmpty ? null : offeringId,
    );
    if (!ctx.mounted) return;
    if (package == null) {
      final allProductsByOffering = await rc.listOfferingProductIds();
      final selectedOfferingProducts = offeringId.isEmpty
          ? const <String>[]
          : (allProductsByOffering[offeringId] ?? const <String>[]);
      final availableProductsPreview = (selectedOfferingProducts.isNotEmpty
              ? selectedOfferingProducts
              : allProductsByOffering.values.expand((ids) => ids))
          .take(8)
          .join(', ');
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;
      _showBoostSubmitErrorDialog(
        title: 'Product not found',
        message:
            'No RevenueCat package matches store product id "$storeProductId". '
            'Check your offering (REVENUECAT_BOOST_OFFERING_ID) and RevenueCat dashboard.\n\n'
            'Plan id: ${plan.id}\n'
            'Target: $_planTarget\n'
            'Offering filter: ${offeringId.isEmpty ? '(none)' : offeringId}\n'
            'Available products: ${availableProductsPreview.isEmpty ? '(none)' : availableProductsPreview}',
      );
      return;
    }

    final iap = await rc.purchaseBoostPackage(package);
    if (!ctx.mounted) return;
    if (iap.userCancelled) {
      await LoaderHelper.hide(ctx);
      return;
    }
    if (!iap.completed) {
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;
      _showBoostSubmitErrorDialog(
        title: 'Purchase failed',
        message: iap.errorMessage ?? 'The store could not complete the purchase.',
      );
      return;
    }

    await LoaderHelper.hide(ctx);
    if (!ctx.mounted) return;
    LoaderHelper.show(ctx, message: 'Activating boost…');
    try {
      await sl<BoostsRepository>().submitBoostOrder(
        businessId: businessId,
        optionType: optionType,
        selectedId: effectiveSelectedId,
        planId: plan.id,
        price: plan.priceFormatted,
        autoRenew: _autoRenew,
      );
    } catch (e, st) {
      debugPrint('submitBoostOrder failed: $e');
      debugPrintStack(stackTrace: st);
      if (!ctx.mounted) return;
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;
      _showBoostSubmitErrorDialog(
        title: 'Boost activation failed',
        message:
            'Your payment may have succeeded, but we could not save the boost. '
            'Contact support with this error:\n\n$e',
      );
      return;
    }
    if (!ctx.mounted) return;
    await LoaderHelper.hide(ctx);
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

  void _showBoostSubmitErrorDialog({
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                _buildRocketHero(),
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
                const SizedBox(height: 20),
                _BenefitsPanel(),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Duration',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(plans.length, (index) {
                  final plan = plans[index];
                  final isSelected = index == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DurationPlanTile(
                      plan: plan,
                      radioValue: index,
                      groupValue: selectedIndex,
                      isSelected: isSelected,
                      onSelect: () => context
                          .read<DashboardCubit>()
                          .setBoostPlanSelected(index),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                _AutoRenewCard(
                  autoRenew: _autoRenew,
                  renewCaption: BoostPlanDisplay.autoRenewCaption(
                    DateTime.now(),
                    selected.durationWeeks,
                  ),
                  onChanged: (v) => setState(() => _autoRenew = v),
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Boost Now • ${selected.priceFormatted}',
                  onPressed: () => _boostNow(selected),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Charged with App Store or Google Play, then your boost goes live',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.start,
                      ),
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

  Widget _buildRocketHero() {
    return SizedBox(
      height: 120,
      child: SvgPicture.asset(
        AppAssets.rocketLaunchSvg,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        placeholderBuilder: (_) => Icon(
          Icons.rocket_launch,
          size: 80,
          color: AppColors.brandSecondary,
        ),
      ),
    );
  }
}

class _BenefitsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        border: Border.all(
          color: AppColors.backgroundGrey.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          _BenefitRow(
            icon: Icons.trending_up,
            title: 'Top of Search',
            description: 'Appear first in local search results',
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.backgroundGrey.withValues(alpha: 0.4),
            indent: 14,
            endIndent: 14,
          ),
          _BenefitRow(
            icon: Icons.verified_outlined,
            title: 'Featured Badge',
            description: 'Stand out with a special badge',
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.backgroundGrey.withValues(alpha: 0.4),
            indent: 14,
            endIndent: 14,
          ),
          _BenefitRow(
            icon: Icons.headset_mic_outlined,
            title: 'Priority Support',
            description: 'Get faster assistance from our team',
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.18),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
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

class _DurationPlanTile extends StatelessWidget {
  const _DurationPlanTile({
    required this.plan,
    required this.radioValue,
    required this.groupValue,
    required this.isSelected,
    required this.onSelect,
  });

  final BoostPlan plan;
  final int radioValue;
  final int groupValue;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final headline = BoostPlanDisplay.durationHeadline(plan.durationWeeks);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandPrimary.withValues(alpha: 0.08)
                : AppColors.backgroundLight.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppResources.radiusL),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandPrimary
                  : AppColors.backgroundGrey.withValues(alpha: 0.45),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Radio<int>(
                  value: radioValue,
                  // ignore: deprecated_member_use
                  groupValue: groupValue,
                  // ignore: deprecated_member_use
                  onChanged: (_) => onSelect(),
                  fillColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.brandPrimary;
                    }
                    return AppColors.textSecondary;
                  }),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (plan.description.isNotEmpty)
                        Text(
                          plan.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.priceFormatted,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (plan.originalPriceFormatted != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        plan.originalPriceFormatted!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoRenewCard extends StatelessWidget {
  const _AutoRenewCard({
    required this.autoRenew,
    required this.renewCaption,
    required this.onChanged,
  });

  final bool autoRenew;
  final String renewCaption;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        border: Border.all(
          color: AppColors.backgroundGrey.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto-Renewal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  renewCaption,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: autoRenew,
            onChanged: onChanged,
            activeThumbColor: AppColors.brandPrimary,
            activeTrackColor: AppColors.brandPrimary.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}
