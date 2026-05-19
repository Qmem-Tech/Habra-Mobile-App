import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/business_subscription_config.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/services/revenue_cat_service.dart';
import '../../../../core/subscription/business_subscription_post_unlock.dart';
import '../../../../core/subscription/business_subscription_tier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../auth/domain/entities/user.dart';
import '../bloc/business_owner_subscription_cubit.dart';

class _LocalPlanConfig {
  const _LocalPlanConfig({
    required this.tier,
    required this.shortLabel,
  });

  final BusinessSubscriptionTier tier;
  final String shortLabel;
}

/// Local mapping by stable store product id (recommended).
const Map<String, _LocalPlanConfig> kProductIdToPlanConfig = {
  'habra_standard_monthly': _LocalPlanConfig(
    tier: BusinessSubscriptionTier.pro,
    shortLabel: 'Standard (Monthly)',
  ),
  'habra_standard_yearly': _LocalPlanConfig(
    tier: BusinessSubscriptionTier.pro,
    shortLabel: 'Standard (Yearly)',
  ),
  'habra_premium_monthly': _LocalPlanConfig(
    tier: BusinessSubscriptionTier.premium,
    shortLabel: 'Premium (Monthly)',
  ),
  'habra_premium_yearly': _LocalPlanConfig(
    tier: BusinessSubscriptionTier.premium,
    shortLabel: 'Premium (Yearly)',
  ),
};

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

  /// 0 = Monthly (and non-annual periods), 1 = Yearly (annual).
  int _billingPeriodTab = 0;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    if (BusinessSubscriptionConfig.mode == BusinessOwnerSubscriptionMode.off) {
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
      _syncBillingPeriodTab();
    });
  }

  void _syncBillingPeriodTab() {
    final monthly = _monthlyPackages;
    final yearly = _yearlyPackages;
    if (monthly.isEmpty && yearly.isNotEmpty) {
      _billingPeriodTab = 1;
    } else if (yearly.isEmpty && monthly.isNotEmpty) {
      _billingPeriodTab = 0;
    }
  }

  bool _packageIsYearly(Package p) {
    switch (p.packageType) {
      case PackageType.annual:
        return true;
      case PackageType.monthly:
      case PackageType.weekly:
        return false;
      default:
        final id = p.storeProduct.identifier.toLowerCase();
        final title = p.storeProduct.title.toLowerCase();
        if (id.contains('year') ||
            id.contains('annual') ||
            id.contains('yearly') ||
            title.contains('year') ||
            title.contains('annual')) {
          return true;
        }
        return false;
    }
  }

  List<Package> get _monthlyPackages =>
      _packages.where((p) => !_packageIsYearly(p)).toList();

  List<Package> get _yearlyPackages =>
      _packages.where(_packageIsYearly).toList();

  List<Package> get _packagesForActiveBillingTab =>
      _billingPeriodTab == 0 ? _monthlyPackages : _yearlyPackages;

  Future<void> _applyUnlockedAndPop(BuildContext ctx) async {
    await BusinessSubscriptionPostUnlock.apply(
      ctx,
      userId: widget.user.id,
      forceRefreshRevenueCat: true,
    );
    if (!ctx.mounted) return;
    Navigator.of(ctx).pop(true);
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
        final subCubit = ctx.read<BusinessOwnerSubscriptionCubit>();
        final active = await BusinessSubscriptionPostUnlock
            .refreshSubscriptionUntilActive(subCubit, widget.user.id);
        if (!ctx.mounted) return;
        if (active) {
          await _applyUnlockedAndPop(ctx);
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
      }
      if (!ctx.mounted) return;
      // StoreKit may succeed while the RC SDK still throws — confirm before failing.
      final subCubit = ctx.read<BusinessOwnerSubscriptionCubit>();
      final active = await BusinessSubscriptionPostUnlock
          .refreshSubscriptionUntilActive(subCubit, widget.user.id);
      if (!ctx.mounted) return;
      if (active) {
        await _applyUnlockedAndPop(ctx);
        return;
      }
      if (ctx.mounted) {
        ErrorDisplayHelper.show(ctx, error: e, title: 'Purchase failed');
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
      final subCubit = ctx.read<BusinessOwnerSubscriptionCubit>();
      final active = await BusinessSubscriptionPostUnlock
          .refreshSubscriptionUntilActive(subCubit, widget.user.id);
      if (!ctx.mounted) return;
      if (active) {
        await _applyUnlockedAndPop(ctx);
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
    final subCubit = context.read<BusinessOwnerSubscriptionCubit>();
    final active = await BusinessSubscriptionPostUnlock
        .refreshSubscriptionUntilActive(subCubit, widget.user.id);
    if (!mounted) return;
    if (active) {
      await _applyUnlockedAndPop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active business tools subscription detected yet.'),
        ),
      );
    }
  }

  BusinessSubscriptionTier _tierForPackage(Package p) {
    final title = p.storeProduct.title.toLowerCase();
    final productId = p.storeProduct.identifier.toLowerCase();
    final packageId = p.identifier.toLowerCase();
    final localConfig = kProductIdToPlanConfig[productId];
    if (localConfig != null) return localConfig.tier;

    if (title.contains('premium') ||
        productId.contains('premium') ||
        packageId.contains('premium')) {
      return BusinessSubscriptionTier.premium;
    }
    if (title.contains('pro') ||
        productId.contains('standard') ||
        productId.contains('_pro') ||
        productId.endsWith('.pro') ||
        packageId.contains('pro')) {
      return BusinessSubscriptionTier.pro;
    }
    return BusinessSubscriptionTier.basic;
  }

  String _shortLabelForPackage(Package p) {
    final productId = p.storeProduct.identifier.toLowerCase();
    final localConfig = kProductIdToPlanConfig[productId];
    if (localConfig != null) return localConfig.shortLabel;

    // Fallback: remove marketplace suffix like "(com.app (unreviewed))".
    final compact = p.storeProduct.title.replaceAll(RegExp(r'\s*\(.*\)\s*$'), '');
    return compact.trim().isEmpty ? p.storeProduct.title : compact.trim();
  }

  List<String> _paragraphs(String s) => s
      .trim()
      .split(RegExp(r'[\r\n]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  List<String> _featureLinesForPackage(Package p) {
    final desc = p.storeProduct.description.trim();
    if (desc.isEmpty) {
      return const [
        'Unlock paid business-owner tools in the app.',
        'Billing is handled securely by the App Store or Google Play.',
      ];
    }
    final paras = _paragraphs(desc);
    if (paras.length >= 2) return paras.sublist(1);
    final bullets = desc
        .split('•')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (bullets.length >= 2) return bullets;
    return [paras.first];
  }

  /// Friendly, marketing-ready bullets by tier (merged with store copy when present).
  List<String> _curatedBulletsForTier(BusinessSubscriptionTier tier) {
    switch (tier) {
      case BusinessSubscriptionTier.premium:
        return const [
          'Everything in Standard—plus extra visibility when competition heats up',
          'Up to 15 gallery photos per listing',
          'Rich analytics: see who finds you and what drives calls and visits',
          'Unlimited active deals, events, and job posts',
          'Boosts and promos to reach more Habra customers when it matters',
        ];
      case BusinessSubscriptionTier.pro:
        return const [
          'Full dashboard with analytics you can act on—not just numbers',
          'Up to 8 gallery photos per listing',
          'Up to 5 active deals, 5 hosted events, and 5 open job posts per listing',
          'Publish and manage deals, job posts, and events in one flow',
          'Verified badge on your listing',
        ];
      case BusinessSubscriptionTier.basic:
        return const [
          'Listing profile and discovery—your business can appear in search when approved',
          'Up to 3 gallery photos per listing',
          'Edit listing details and hours',
          'Customer reviews visible on your profile',
        ];
    }
  }

  List<String> _includedFeaturesForPackage(Package p) {
    final tier = _tierForPackage(p);
    final merged = <String>[..._curatedBulletsForTier(tier)];
    for (final line in _featureLinesForPackage(p)) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final dup = merged.any(
        (m) => m.toLowerCase() == t.toLowerCase(),
      );
      if (!dup) merged.add(t);
    }
    return merged;
  }

  String _subtitleForPackage(Package p) {
    final desc = p.storeProduct.description.trim();
    if (desc.isEmpty) return 'Subscription';
    final paras = _paragraphs(desc);
    if (paras.length >= 2) return paras.first;
    return 'Grow with Habra business tools';
  }

  String _billingSuffix(Package pkg) {
    switch (pkg.packageType) {
      case PackageType.monthly:
        return '/ month';
      case PackageType.annual:
        return '/ year';
      case PackageType.weekly:
        return '/ week';
      case PackageType.lifetime:
        return '';
      case PackageType.sixMonth:
      case PackageType.threeMonth:
      case PackageType.twoMonth:
        return '/ period';
      case PackageType.custom:
      case PackageType.unknown:
        return '/ period';
    }
  }

  IconData _iconForPackage(Package p) {
    switch (_tierForPackage(p)) {
      case BusinessSubscriptionTier.premium:
        return Icons.workspace_premium_rounded;
      case BusinessSubscriptionTier.pro:
        return Icons.stars_rounded;
      case BusinessSubscriptionTier.basic:
        return Icons.card_membership_rounded;
    }
  }

  bool _isPopular(Package p, int indexInTab, List<Package> tabPackages) {
    if (_tierForPackage(p) == BusinessSubscriptionTier.premium) return true;
    return indexInTab == 0 && tabPackages.length == 1;
  }

  bool _highlighted(
    Package p,
    int indexInTab,
    List<Package> tabPackages,
  ) =>
      _isPopular(p, indexInTab, tabPackages);

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
            return _buildActiveBody(subState.currentTier);
          }
          return _buildRevenueCatBody(subState.currentTier);
        },
      ),
    );
  }

  Widget _buildRevenueCatBody(BusinessSubscriptionTier currentTier) {
    if (!di.sl<RevenueCatService>().isInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingL),
          child: Text(
            'In-app billing is not configured in this build (add RevenueCat API keys).',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      );
    }
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
          if (!_loadingPackages &&
              _monthlyPackages.isNotEmpty &&
              _yearlyPackages.isNotEmpty) ...[
            _buildBillingPeriodTabs(),
            const SizedBox(height: 8),
          ],
          if (_loadingPackages)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (_packagesError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _packagesError!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (!_loadingPackages &&
                _packages.isNotEmpty &&
                _packagesForActiveBillingTab.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  _billingPeriodTab == 0
                      ? 'No monthly plans are linked yet. Switch to Yearly or check RevenueCat.'
                      : 'No yearly plans are linked yet. Switch to Monthly or check RevenueCat.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            for (var i = 0; i < _packagesForActiveBillingTab.length; i++) ...[
              _RevenueCatPlanTile(
                package: _packagesForActiveBillingTab[i],
                planTitle: _shortLabelForPackage(_packagesForActiveBillingTab[i]),
                subtitle: _subtitleForPackage(_packagesForActiveBillingTab[i]),
                icon: _iconForPackage(_packagesForActiveBillingTab[i]),
                features: _includedFeaturesForPackage(_packagesForActiveBillingTab[i]),
                priceLabel:
                    _packagesForActiveBillingTab[i].storeProduct.priceString,
                billingSuffix:
                    _billingSuffix(_packagesForActiveBillingTab[i]),
                highlighted: _highlighted(
                  _packagesForActiveBillingTab[i],
                  i,
                  _packagesForActiveBillingTab,
                ),
                popular: _isPopular(
                  _packagesForActiveBillingTab[i],
                  i,
                  _packagesForActiveBillingTab,
                ),
                current: currentTier ==
                    _tierForPackage(_packagesForActiveBillingTab[i]),
                onTap: _purchasing
                    ? null
                    : () => _onPurchase(_packagesForActiveBillingTab[i]),
              ),
              const SizedBox(height: 10),
            ],
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
          ],
          const SizedBox(height: 14),
          _buildWhyUpgradeSection(),
          const SizedBox(height: 12),
          if (!_loadingPackages && (_packages.isNotEmpty || _packagesError != null))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _packages.isEmpty
                          ? 'No paid packages in this offering.'
                          : '${_packages.length} plan(s) from RevenueCat.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadPackages,
                    child: const Text('Reload plans'),
                  ),
                ],
              ),
            ),
          if (!_loadingPackages && di.sl<RevenueCatService>().isInitialized)
            AppOutlinedButton(
              text: 'Restore purchases',
              onPressed: _purchasing ? null : _onRestore,
              textColor: AppColors.brandPrimary,
              borderColor: AppColors.brandPrimary,
            ),
          const SizedBox(height: 8),
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

  Widget _buildBillingPeriodTabs() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment<int>(
            value: 0,
            label: Text('Monthly'),
            icon: Icon(Icons.calendar_month_rounded, size: 18),
          ),
          ButtonSegment<int>(
            value: 1,
            label: Text('Yearly'),
            icon: Icon(Icons.calendar_today_rounded, size: 18),
          ),
        ],
        selected: {_billingPeriodTab},
        onSelectionChanged: (Set<int> selection) {
          setState(() => _billingPeriodTab = selection.first);
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.brandPrimary,
          selectedForegroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: Color(0xFFD9D9D9)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
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

  Widget _buildActiveBody(BusinessSubscriptionTier currentTier) {
    if (BusinessSubscriptionConfig.mode == BusinessOwnerSubscriptionMode.off) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded,
                  size: 64, color: AppColors.brandSecondary),
              const SizedBox(height: 20),
              const Text(
                'Business tools are active',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Subscription gating is turned off for this build.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4),
              ),
              const SizedBox(height: 28),
              AppButton(
                  text: 'Done', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      );
    }

    final isPremium = currentTier == BusinessSubscriptionTier.premium;
    final planName = isPremium ? 'Premium' : 'Standard';
    final planIcon =
        isPremium ? Icons.workspace_premium_rounded : Icons.stars_rounded;
    final planColor =
        isPremium ? const Color(0xFFB8860B) : AppColors.brandPrimary;
    final features = _curatedBulletsForTier(currentTier);

    // Find the package for upgrade / downgrade
    Package? upgradePackage;
    Package? downgradePackage;
    if (!isPremium) {
      upgradePackage = _packages.where((p) {
        final id = p.storeProduct.identifier.toLowerCase();
        final isSamePeriod = _billingPeriodTab == 0
            ? !_packageIsYearly(p)
            : _packageIsYearly(p);
        return id.contains('premium') && isSamePeriod;
      }).firstOrNull;
      upgradePackage ??= _packages
          .where((p) => p.storeProduct.identifier.toLowerCase().contains('premium'))
          .firstOrNull;
    } else {
      downgradePackage = _packages.where((p) {
        final id = p.storeProduct.identifier.toLowerCase();
        final isSamePeriod = _billingPeriodTab == 0
            ? !_packageIsYearly(p)
            : _packageIsYearly(p);
        return id.contains('standard') && isSamePeriod;
      }).firstOrNull;
      downgradePackage ??= _packages
          .where((p) => p.storeProduct.identifier.toLowerCase().contains('standard'))
          .firstOrNull;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppResources.spacingM, vertical: AppResources.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // — Plan card —
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: planColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: planColor.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(planIcon, color: planColor, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      '$planName Plan',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: planColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 17, color: planColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(f,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // — Upgrade action —
          if (!isPremium && upgradePackage != null) ...[
            Text(
              'Want more?',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            AppButton(
              text: _purchasing
                  ? 'Processing…'
                  : 'Upgrade to Premium — ${upgradePackage.storeProduct.priceString}',
              onPressed: _purchasing ? null : () => _onPurchase(upgradePackage!),
            ),
            const SizedBox(height: 20),
          ],

          // — Downgrade action —
          if (isPremium && downgradePackage != null) ...[
            Text(
              'Want to switch?',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed:
                  _purchasing ? null : () => _onPurchase(downgradePackage!),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandPrimary,
                side: BorderSide(color: AppColors.brandPrimary),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _purchasing
                    ? 'Processing…'
                    : 'Switch to Standard — ${downgradePackage.storeProduct.priceString}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
          ],

          const Divider(),
          const SizedBox(height: 12),

          // — Manage / Cancel —
          Text(
            'Manage subscription',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'To cancel or manage billing, go to Settings → [your name] → Subscriptions on your iPhone.',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('https://apps.apple.com/account/subscriptions'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open App Store subscriptions'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Paywall row built from a RevenueCat [Package] (collapsible “What’s included”, store price).
class _RevenueCatPlanTile extends StatelessWidget {
  const _RevenueCatPlanTile({
    required this.package,
    required this.planTitle,
    required this.subtitle,
    required this.icon,
    required this.features,
    required this.priceLabel,
    required this.billingSuffix,
    this.highlighted = false,
    this.popular = false,
    this.current = false,
    this.onTap,
  });

  final Package package;
  final String planTitle;
  final String subtitle;
  final IconData icon;
  final List<String> features;
  final String priceLabel;
  final String billingSuffix;
  final bool highlighted;
  final bool popular;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(package.identifier),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        border: Border.all(
          color: highlighted ? AppColors.brandPrimary : const Color(0xFFD9D9D9),
          width: highlighted ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          child: Icon(icon,
                              color: AppColors.brandPrimary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                planTitle,
                                style: const TextStyle(
                                  fontSize: 16,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F3EA),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Popular',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceLabel,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (billingSuffix.isNotEmpty)
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
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              iconColor: AppColors.brandPrimary,
              collapsedIconColor: AppColors.textSecondary,
              title: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'What\'s included',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Compare benefits—your subscription is billed securely by the store.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: features.map(_featureRow).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppColors.brandPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF454545),
                height: 1.45,
              ),
            ),
          ),
        ],
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
    required this.current,
  });

  final String name;
  final String subtitle;
  final IconData icon;
  final List<String> features;
  final String monthlyPrice;
  final String billingSuffix;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
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
                        color: const Color(0xFFF4F4F4),
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
                        onPressed: null,
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
