import 'package:flutter/foundation.dart';

import 'business_subscription_tier.dart';

/// Subscription diagnostics — uses [debugPrint] so lines appear as `flutter: ...` in
/// the terminal (same as RevenueCat `[RC]` logs).
void subscriptionLog(String message) {
  debugPrint('[Subscription] $message');
}

void subscriptionLogPlan({
  required String source,
  required String userId,
  BusinessSubscriptionTier? revenueCatTier,
  bool? revenueCatActive,
  BusinessSubscriptionTier? supabaseTier,
  String? businessName,
}) {
  final parts = <String>['source=$source', 'userId=$userId'];
  if (businessName != null) parts.add('business="$businessName"');
  if (revenueCatActive != null) parts.add('RC.active=$revenueCatActive');
  if (revenueCatTier != null) {
    parts.add('RC.plan=${revenueCatTier.displayName} (${revenueCatTier.name})');
  }
  if (supabaseTier != null) {
    parts.add('DB.plan=${supabaseTier.displayName} (${supabaseTier.name})');
  }
  subscriptionLog(parts.join(' | '));
}
