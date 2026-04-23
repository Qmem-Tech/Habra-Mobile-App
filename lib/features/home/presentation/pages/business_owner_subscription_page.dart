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
          icon: const Icon(Icons.close),
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
        final currentTier = context
            .read<BusinessOwnerSubscriptionCubit>()
            .state
            .currentTier;
        return [
          _PlanTile(
            name: 'Premium',
            description:
                'Featured in top search, deals/events promotions, verified badge, advanced analytics.',
            priceLabel: '\$29.99 / month',
            highlighted: true,
            current: currentTier == BusinessSubscriptionTier.premium,
            onTap: _openingHostedCheckout
                ? null
                : () => _onChooseProfileTier(BusinessSubscriptionTier.premium),
          ),
          const SizedBox(height: 10),
          _PlanTile(
            name: 'Pro',
            description:
                'Deals/events promotions, verified badge, basic analytics.',
            priceLabel: '\$14.99 / month',
            current: currentTier == BusinessSubscriptionTier.pro,
            onTap: _openingHostedCheckout
                ? null
                : () => _onChooseProfileTier(BusinessSubscriptionTier.pro),
          ),
          const SizedBox(height: 10),
          _PlanTile(
            name: 'Basic',
            description: 'Business listing, reviews, and basic insights.',
            priceLabel: 'Free',
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
              BusinessSubscriptionConfig.mode == BusinessOwnerSubscriptionMode.off
                  ? 'Subscription gating is turned off for this build.'
                  : 'You can use the Dashboard tab. Manage or cancel your plan in the App Store or Google Play subscriptions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
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
    required this.description,
    required this.priceLabel,
    this.highlighted = false,
    this.current = false,
    this.onTap,
  });

  final String name;
  final String description;
  final String priceLabel;
  final bool highlighted;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        border: Border.all(
          color: highlighted ? AppColors.brandPrimary : AppColors.backgroundGrey,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(AppResources.spacingM),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                priceLabel,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              AppOutlinedButton(
                text: current ? 'Current Plan' : 'Choose Plan',
                onPressed: current ? null : onTap,
                textColor:
                    current ? AppColors.textSecondary : AppColors.brandPrimary,
                borderColor:
                    current ? AppColors.backgroundGrey : AppColors.brandPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
