import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/home/presentation/pages/payouts_setup_page.dart';

/// Stripe Connect payout requirements for business owners selling event tickets.
abstract final class BusinessPayoutGate {
  static bool isComplete(String? stripeConnectStatus) =>
      stripeConnectStatus == 'complete';

  static Future<String?> fetchConnectStatus(String businessId) async {
    final res = await Supabase.instance.client
        .from('businesses')
        .select('stripe_connect_status')
        .eq('id', businessId)
        .maybeSingle();
    return res?['stripe_connect_status'] as String?;
  }

  /// Opens [PayoutsSetupPage]. Returns `true` if connect status is complete after return.
  static Future<bool> openPayoutSetup(
    BuildContext context, {
    required String businessId,
    required String businessName,
  }) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PayoutsSetupPage(
          businessId: businessId,
          businessName: businessName,
        ),
      ),
    );
    if (!context.mounted) return false;
    final status = await fetchConnectStatus(businessId);
    return isComplete(status);
  }

  /// Blocks event **creation** until payouts are set up. Editing existing events is allowed.
  static Future<bool> ensureCanCreateEvents(
    BuildContext context, {
    required String businessId,
    required String businessName,
  }) async {
    var status = await fetchConnectStatus(businessId);
    if (isComplete(status)) return true;

    final completed = await openPayoutSetup(
      context,
      businessId: businessId,
      businessName: businessName,
    );
    if (!context.mounted) return false;
    if (completed) return true;

    status = await fetchConnectStatus(businessId);
    if (!isComplete(status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Set up payout details before creating events so you can receive ticket sales.',
          ),
        ),
      );
    }
    return isComplete(status);
  }
}
