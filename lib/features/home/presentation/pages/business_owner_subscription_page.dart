import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/config/business_subscription_config.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/services/business_subscription_checkout_service.dart';
import '../../../../core/services/revenue_cat_service.dart';
import '../../../../core/subscription/business_subscription_tier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../auth/domain/entities/user.dart';
import '../bloc/business_owner_subscription_cubit.dart';

/// Paywall / status screen for business-owner tools subscription (Dashboard gate).
class BusinessOwnerSubscriptionPage extends StatefulWidget {
  const BusinessOwnerSubscriptionPage({super.key, required this.user});

  final User user;

  @override
  State<BusinessOwnerSubscriptionPage> createState() =>
      _BusinessOwnerSubscriptionPageState();
}

class _BusinessOwnerSubscriptionPageState
    extends State<BusinessOwnerSubscriptionPage> {
  List<Package> _packages = [];
  bool _loadingPackages = true;
  String? _packagesError;
  bool _purchasing = false;
  bool _openingHostedCheckout = false;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    if (BusinessSubscriptionConfig.mode !=
        BusinessOwnerSubscriptionMode.revenuecat) {
      if (mounted) {
        setState(() {
          _loadingPackages = false;
          _packages = [];
        });
      }
      return;
    }
    setState(() {
      _loadingPackages = true;
      _packagesError = null;
    });
    final id = BusinessSubscriptionConfig.revenueCatOfferingIdentifier;
    final list = await di.sl<RevenueCatService>().getOwnerToolsPackages(
      offeringIdentifier: id.isEmpty ? null : id,
    );
    if (!mounted) return;
    setState(() {
      _packages = list;
      _loadingPackages = false;
      if (list.isEmpty && di.sl<RevenueCatService>().isInitialized) {
        _packagesError =
            'No subscription products are available yet. Check RevenueCat offerings and App Store / Play configuration.';
      }
    });
  }

  Future<void> _onPurchase(Package package) async {
    if (_purchasing) return;
    setState(() => _purchasing = true);
    final ctx = context;
    LoaderHelper.show(ctx, message: 'Processing…');
    try {
      final ok = await di.sl<RevenueCatService>().purchasePackage(package);
      if (!ctx.mounted) return;
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;
      if (ok) {
        await ctx.read<BusinessOwnerSubscriptionCubit>().refresh(widget.user.id);
        if (!ctx.mounted) return;
        if (ctx.read<BusinessOwnerSubscriptionCubit>().state
            .hasActiveSubscription) {
          Navigator.of(ctx).pop(true);
          return;
        }
      }
      if (ctx.mounted) {
        ErrorDisplayHelper.show(
          ctx,
          title: 'Purchase incomplete',
          message:
              'We could not confirm your subscription. If you were charged, use Restore purchases.',
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
        if (ctx.mounted) {
          ErrorDisplayHelper.show(ctx, error: e, title: 'Purchase failed');
        }
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _onRestore() async {
    final ctx = context;
    LoaderHelper.show(ctx, message: 'Restoring…');
    try {
      await di.sl<RevenueCatService>().restorePurchases();
      if (!ctx.mounted) return;
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;
      await ctx.read<BusinessOwnerSubscriptionCubit>().refresh(widget.user.id);
      if (!ctx.mounted) return;
      if (ctx.read<BusinessOwnerSubscriptionCubit>().state
          .hasActiveSubscription) {
        Navigator.of(ctx).pop(true);
      } else {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('No active subscription found for this account.'),
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
        if (ctx.mounted) {
          ErrorDisplayHelper.show(ctx, error: e, title: 'Restore failed');
        }
      }
    }
  }

  Future<void> _onRefreshStatus() async {
    await context.read<BusinessOwnerSubscriptionCubit>().refresh(widget.user.id);
    if (!mounted) return;
    if (context.read<BusinessOwnerSubscriptionCubit>().state
        .hasActiveSubscription) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active business tools subscription detected yet.'),
        ),
      );
    }
  }

  Future<void> _onManagePlan() async {
    final ok = await di.sl<BusinessSubscriptionCheckoutService>().openPortal();
    if (!mounted) return;
    if (!ok) {
      ErrorDisplayHelper.show(
        context,
        title: 'Billing portal unavailable',
        message:
            'Could not open Stripe billing portal. Verify portal function deployment and customer portal settings in Stripe.',
      );
    }
  }

  Future<void> _onChooseProfileTier(BusinessSubscriptionTier tier) async {
    if (_openingHostedCheckout) return;
    if (tier == BusinessSubscriptionTier.basic) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Basic is your free default plan.'),
        ),
      );
      return;
    }
    setState(() => _openingHostedCheckout = true);
    final ok = await di.sl<BusinessSubscriptionCheckoutService>().openCheckout(
      tier,
    );
    if (!mounted) return;
    setState(() => _openingHostedCheckout = false);
    if (!ok) {
      ErrorDisplayHelper.show(
        context,
        title: 'Checkout unavailable',
        message:
            'Could not open hosted checkout. Please verify Stripe checkout function deployment.',
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Complete payment in browser, then tap "Refresh subscription status".',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Grow Your Business',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<BusinessOwnerSubscriptionCubit,
          BusinessOwnerSubscriptionState>(
        builder: (context, subState) {
          if (subState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (subState.hasActiveSubscription ||
              BusinessSubscriptionConfig.mode == BusinessOwnerSubscriptionMode.off) {
            return _buildActiveBody();
          }
          if (BusinessSubscriptionConfig.mode ==
              BusinessOwnerSubscriptionMode.profile) {
            return _buildProfileModeBody(subState.currentTier);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppResources.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeadline(),
                const SizedBox(height: AppResources.spacingL),
                _buildBenefits(),
                const SizedBox(height: AppResources.spacingL),
                ..._buildModeSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileModeBody(BusinessSubscriptionTier currentTier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppResources.spacingM,
        vertical: AppResources.spacingS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPromoHeroCard(),
          const SizedBox(height: 18),
          _buildChoosePlanHeader(),
          const SizedBox(height: 12),
          _PlanTile(
            name: 'Premium',
            subtitle: 'Best for growing businesses',
            icon: Icons.workspace_premium_rounded,
            features: const [
              'Featured in top of search results',
              'Show deals & promotions',
              'Post events',
              'Verified badge',
              'Advanced analytics (views, calls, clicks)',
            ],
            monthlyPrice: '\$29.99',
            highlighted: true,
            popular: true,
            current: currentTier == BusinessSubscriptionTier.premium,
            onTap: _openingHostedCheckout
                ? null
                : () => _onChooseProfileTier(BusinessSubscriptionTier.premium),
          ),
          const SizedBox(height: 10),
          _PlanTile(
            name: 'Pro',
            subtitle: 'Great for small businesses',
            icon: Icons.stars_rounded,
            features: const [
              'Show deals & promotions',
              'Post events',
              'Verified badge',
              'Basic analytics (views & calls)',
            ],
            monthlyPrice: '\$14.99',
            current: currentTier == BusinessSubscriptionTier.pro,
            onTap: _openingHostedCheckout
                ? null
                : () => _onChooseProfileTier(BusinessSubscriptionTier.pro),
          ),
          const SizedBox(height: 10),
          _PlanTile(
            name: 'Basic',
            subtitle: 'Get started with essentials',
            icon: Icons.storefront_rounded,
            features: const [
              'Business listing',
              'Customer reviews',
              'Basic insights',
            ],
            monthlyPrice: 'Free',
            billingSuffix: '/ forever',
            current: currentTier == BusinessSubscriptionTier.basic,
          ),
          const SizedBox(height: 14),
          _buildWhyUpgradeSection(),
          const SizedBox(height: 12),
          _buildLegalFooter(),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: _onRefreshStatus,
              child: const Text('Refresh subscription status'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoHeroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0E5D42),
            Color(0xFF0F6C4A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded, size: 14, color: Color(0xFFFFD466)),
                SizedBox(width: 6),
                Text(
                  'Unlock More Visibility',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Get More Customers\nWith Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Stand out. Get seen. Grow faster.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              _HeroStat(icon: Icons.visibility_outlined, label: 'More Views'),
              _HeroStat(icon: Icons.call_outlined, label: 'More Calls'),
              _HeroStat(icon: Icons.groups_outlined, label: 'More Customers'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoosePlanHeader() {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Choose Your Plan',
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Icon(Icons.verified_user_outlined, size: 16, color: AppColors.textSecondary),
        SizedBox(width: 4),
        Text(
          'Cancel Anytime',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWhyUpgradeSection() {
    Widget item(IconData icon, String text) {
      return Expanded(
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.brandPrimary),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.25,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Why Upgrade?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              item(Icons.people_outline_rounded, 'Reach more\nlocal customers'),
              item(Icons.trending_up_rounded, 'Get more calls\nand visits'),
              item(Icons.verified_outlined, 'Build trust with\nverified badge'),
              item(Icons.campaign_outlined, 'Promote deals\nand events'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalFooter() {
    return Text.rich(
      TextSpan(
        text: 'By continuing, you agree to our ',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        children: [
          TextSpan(
            text: 'Terms of Service',
            style: TextStyle(
              color: AppColors.brandPrimary,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy.',
            style: TextStyle(
              color: AppColors.brandPrimary,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildHeadline() {
    return const Text(
      'Get More Customers With Premium',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.2,
      ),
    );
  }

  Widget _buildBenefits() {
    const items = [
      'More views',
      'More calls',
      'More customers',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Included',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.brandPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle,
                    size: 22, color: AppColors.brandSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildModeSection(BuildContext context) {
    switch (BusinessSubscriptionConfig.mode) {
      case BusinessOwnerSubscriptionMode.off:
        return [];
      case BusinessOwnerSubscriptionMode.stubLocked:
        return [
          Text(
            'This build uses stub subscription mode (always locked) for testing the paywall UI.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ];
      case BusinessOwnerSubscriptionMode.profile:
        final currentTier = context.read<BusinessOwnerSubscriptionCubit>().state.currentTier;
        return [
          _PlanTile(
            name: 'Premium',
            subtitle: 'Best for growing businesses',
            icon: Icons.workspace_premium_rounded,
            features: const [
              'Featured in top search',
              'Deals/events promotions',
              'Verified badge',
              'Advanced analytics',
            ],
            monthlyPrice: '\$29.99',
            highlighted: true,
            popular: true,
            current: currentTier == BusinessSubscriptionTier.premium,
            onTap: _openingHostedCheckout
                ? null
                : () => _onChooseProfileTier(BusinessSubscriptionTier.premium),
          ),
          const SizedBox(height: 10),
          _PlanTile(
            name: 'Pro',
            subtitle: 'Great for small businesses',
            icon: Icons.stars_rounded,
            features: const [
              'Deals/events promotions',
              'Verified badge',
              'Basic analytics',
            ],
            monthlyPrice: '\$14.99',
            current: currentTier == BusinessSubscriptionTier.pro,
            onTap: _openingHostedCheckout
                ? null
                : () => _onChooseProfileTier(BusinessSubscriptionTier.pro),
          ),
          const SizedBox(height: 10),
          _PlanTile(
            name: 'Basic',
            subtitle: 'Get started with essentials',
            icon: Icons.storefront_rounded,
            features: const ['Business listing', 'Customer reviews', 'Basic insights'],
            monthlyPrice: 'Free',
            billingSuffix: '/ forever',
            current: currentTier == BusinessSubscriptionTier.basic,
            onTap: null,
          ),
          const SizedBox(height: 16),
          Text(
            'Your plan is tied to your Habra account. If you subscribed on the web or through support, refresh after payment clears.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            text: 'Refresh subscription status',
            onPressed: _onRefreshStatus,
          ),
        ];
      case BusinessOwnerSubscriptionMode.revenuecat:
        if (!di.sl<RevenueCatService>().isInitialized) {
          return [
            Text(
              'In-app billing is not configured in this build (add RevenueCat API keys).',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ];
        }
        if (_loadingPackages) {
          return [
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          ];
        }
        if (_packagesError != null && _packages.isEmpty) {
          return [
            Text(
              _packagesError!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadPackages,
              child: const Text('Retry'),
            ),
          ];
        }
        return [
          ..._packages.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PackageCard(
                package: p,
                busy: _purchasing,
                onTap: () => _onPurchase(p),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AppOutlinedButton(
            text: 'Restore purchases',
            onPressed: _purchasing ? null : _onRestore,
            textColor: AppColors.brandPrimary,
            borderColor: AppColors.brandPrimary,
          ),
        ];
    }
  }

  Widget _buildActiveBody() {
    final isProfileMode =
        BusinessSubscriptionConfig.mode == BusinessOwnerSubscriptionMode.profile;
    final message = BusinessSubscriptionConfig.mode ==
            BusinessOwnerSubscriptionMode.off
        ? 'Subscription gating is turned off for this build.'
        : (isProfileMode
            ? 'Your subscription is managed via Habra billing. You can manage or cancel your plan in the billing portal.'
            : 'You can use the Dashboard tab. Manage or cancel your plan in the App Store or Google Play subscriptions.');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppResources.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_rounded,
                size: 72, color: AppColors.brandSecondary),
            const SizedBox(height: 20),
            const Text(
              'Business tools are active',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (isProfileMode) ...[
              const SizedBox(height: 16),
              AppOutlinedButton(
                text: 'Manage plan',
                onPressed: _onManagePlan,
                textColor: AppColors.brandPrimary,
                borderColor: AppColors.brandPrimary,
              ),
            ],
            const SizedBox(height: 28),
            AppButton(
              text: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.onTap,
    required this.busy,
  });

  final Package package;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    final title = product.title;
    final price = product.priceString;
    final desc = product.description;
    final lower = title.toLowerCase();
    final tierLabel = lower.contains('premium')
        ? 'Premium'
        : (lower.contains('pro') ? 'Pro' : title);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppResources.spacingM),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(AppResources.radiusM),
            color: AppColors.brandPrimary.withValues(alpha: 0.06),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierLabel,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.features,
    required this.monthlyPrice,
    this.billingSuffix = '/ month',
    this.highlighted = false,
    this.popular = false,
    this.current = false,
    this.onTap,
  });

  final String name;
  final String subtitle;
  final IconData icon;
  final List<String> features;
  final String monthlyPrice;
  final String billingSuffix;
  final bool highlighted;
  final bool popular;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        border: Border.all(color: highlighted ? AppColors.brandPrimary : const Color(0xFFD9D9D9), width: highlighted ? 1.5 : 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: highlighted
                            ? AppColors.brandPrimary.withValues(alpha: 0.12)
                            : const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: AppColors.brandPrimary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (popular)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F3EA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Most Popular',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check, size: 15, color: Color(0xFF4E4E4E)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF454545),
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                monthlyPrice,
                style: const TextStyle(
                  fontSize: 33,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                billingSuffix,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 116,
                height: 38,
                child: current
                    ? AppOutlinedButton(
                        text: 'Current Plan',
                        onPressed: null,
                        textColor: AppColors.textSecondary,
                        borderColor: AppColors.backgroundGrey,
                      )
                    : AppButton(
                        text: 'Choose Plan',
                        onPressed: onTap,
                        backgroundColor: AppColors.brandPrimary,
                        textColor: Colors.white,
                        height: 38,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.white.withValues(alpha: 0.88)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
