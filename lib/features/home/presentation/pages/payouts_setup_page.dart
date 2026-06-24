import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';

/// Guides the business owner through Stripe Connect onboarding so they can
/// receive automatic payouts from event ticket sales.
///
/// Flow:
///  1. Load the connect status from `businesses.stripe_connect_status`.
///  2. If not complete → call the `create-connect-account` edge function to
///     get an onboarding URL, then open it in the browser.
///  3. Stripe redirects back to the app; owner taps "I've completed setup"
///     to refresh the status.
class PayoutsSetupPage extends StatefulWidget {
  const PayoutsSetupPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  State<PayoutsSetupPage> createState() => _PayoutsSetupPageState();
}

class _PayoutsSetupPageState extends State<PayoutsSetupPage> {
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;
  String _connectStatus = 'pending'; // pending | restricted | complete

  static const String _returnUrl = 'https://habra.app/connect/return';
  static const String _refreshUrl = 'https://habra.app/connect/refresh';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Supabase.instance.client
          .from('businesses')
          .select('stripe_connect_status')
          .eq('id', widget.businessId)
          .maybeSingle();

      if (!mounted) return;
      final status = (res?['stripe_connect_status'] as String?) ?? 'pending';
      setState(() {
        _connectStatus = status;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load payout status. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _openStripeUrl({required bool managePayouts}) async {
    setState(() {
      _actionLoading = true;
      _error = null;
    });
    try {
      final body = <String, dynamic>{
        'business_id': widget.businessId,
      };
      if (managePayouts) {
        body['manage_payouts'] = true;
      } else {
        body['return_url'] = _returnUrl;
        body['refresh_url'] = _refreshUrl;
      }
      final res = await Supabase.instance.client.functions.invoke(
        'create-connect-account',
        body: body,
      );

      if (!mounted) return;

      final data = res.data as Map<String, dynamic>?;
      final url = data?['url'] as String?;
      if (url == null || url.isEmpty) {
        setState(() {
          _error = data?['error'] as String? ??
              (managePayouts
                  ? 'Could not open payout settings.'
                  : 'Could not create onboarding link.');
          _actionLoading = false;
        });
        return;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() {
          _error = 'Could not open browser. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong: $e';
      });
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _startOnboarding() => _openStripeUrl(managePayouts: false);

  Future<void> _managePayoutSettings() => _openStripeUrl(managePayouts: true);

  Future<void> _refreshStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Call the edge function with check_status=true so it reads directly
      // from the Stripe API and syncs the DB — no webhook dependency.
      final res = await Supabase.instance.client.functions.invoke(
        'create-connect-account',
        body: {
          'business_id': widget.businessId,
          'check_status': true,
        },
      );
      if (!mounted) return;
      final data = res.data as Map<String, dynamic>?;
      final status = (data?['status'] as String?) ?? 'pending';
      setState(() {
        _connectStatus = status;
        _loading = false;
      });
      if (status == 'complete') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payouts are now active! You will receive funds after each sale.'),
            backgroundColor: Color(0xFF1B4332),
          ),
        );
      } else if (status == 'restricted') {
        final reqs = data?['requirements'] as Map<String, dynamic>?;
        final due = (reqs?['currently_due'] as List?)?.cast<String>() ?? [];
        final msg = due.isNotEmpty
            ? 'Still needed: ${due.take(3).join(', ')}${due.length > 3 ? '…' : ''}'
            : 'Stripe still needs more information to enable payouts.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not check status: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Payout Setup'),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppResources.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: AppResources.spacingL),
                    _buildHowItWorksCard(),
                    const SizedBox(height: AppResources.spacingL),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppResources.spacingM),
                        child: Text(
                          _error!,
                          style: AppFonts.body(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_connectStatus == 'complete') ...[
                      _buildManagePayoutsButton(),
                      const SizedBox(height: AppResources.spacingM),
                      _buildRefreshStatusButton(),
                    ] else ...[
                      _buildActionButton(),
                      const SizedBox(height: AppResources.spacingM),
                      _buildAlreadyDoneButton(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final (icon, title, subtitle, color) = switch (_connectStatus) {
      'complete' => (
          Icons.verified_rounded,
          'Payouts active',
          'You will automatically receive funds 2–7 business days after each ticket sale. '
              'Use “Manage payout settings” to update your bank account or view payout history on Stripe.',
          const Color(0xFF1B4332),
        ),
      'restricted' => (
          Icons.warning_amber_rounded,
          'Action required',
          'Stripe needs more information to enable your payouts. Tap "Continue setup" below.',
          Colors.orange,
        ),
      _ => (
          Icons.account_balance_wallet_outlined,
          'Set up payouts',
          'Connect your bank account to receive earnings from your event ticket sales.',
          AppColors.brandPrimary,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: AppResources.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.body(color: color).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (_connectStatus == 'complete')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: AppFonts.caption(color: Colors.white)
                        .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppResources.spacingS),
          Text(subtitle, style: AppFonts.body(color: AppColors.textSecondary)),
          const SizedBox(height: AppResources.spacingS),
          Text(
            'Business: ${widget.businessName}',
            style: AppFonts.caption(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How payouts work',
            style: AppFonts.body(color: AppColors.textPrimary)
                .copyWith(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: AppResources.spacingM),
          ...[
            (Icons.local_activity_outlined,
                'Customer buys a ticket',
                'They pay the face value with no extra fees.'),
            (Icons.account_balance_outlined,
                'Habra processes the payment',
                'A 13.5% platform fee covers Stripe\'s cost and Habra\'s 10% commission.'),
            (Icons.payments_outlined,
                'You receive 86.5% automatically',
                'Stripe deposits funds directly into your bank account within 2–7 business days.'),
          ].map((item) {
            final (icon, title, body) = item;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppResources.spacingM),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: AppColors.brandPrimary),
                  ),
                  const SizedBox(width: AppResources.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppFonts.body(color: AppColors.textPrimary)
                                .copyWith(fontWeight: FontWeight.w600)),
                        Text(body,
                            style: AppFonts.caption(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(),
          const SizedBox(height: AppResources.spacingS),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Example: \$50 ticket → \$43.25 to you, \$5.00 to Habra, \$1.75 Stripe fee.',
                  style: AppFonts.caption(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final label = _connectStatus == 'restricted' ? 'Continue setup' : 'Set up payouts';
    return FilledButton.icon(
      onPressed: _actionLoading ? null : _startOnboarding,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: _actionLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.open_in_browser_rounded),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    );
  }

  Widget _buildManagePayoutsButton() {
    return FilledButton.icon(
      onPressed: _actionLoading ? null : _managePayoutSettings,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: _actionLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.settings_outlined),
      label: const Text(
        'Manage payout settings',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }

  Widget _buildRefreshStatusButton() {
    return OutlinedButton.icon(
      onPressed: _actionLoading ? null : _refreshStatus,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandPrimary,
        side: const BorderSide(color: AppColors.brandPrimary),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Refresh status'),
    );
  }

  Widget _buildAlreadyDoneButton() {
    return OutlinedButton.icon(
      onPressed: _actionLoading ? null : _refreshStatus,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandPrimary,
        side: const BorderSide(color: AppColors.brandPrimary),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.refresh_rounded),
      label: const Text("I've completed setup – check status"),
    );
  }
}
