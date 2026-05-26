enum BusinessSubscriptionTier {
  basic,
  pro,
  premium,
}

/// User-facing plan name (Basic / Standard / Premium).
extension BusinessSubscriptionTierDisplay on BusinessSubscriptionTier {
  String get displayName => switch (this) {
        BusinessSubscriptionTier.premium => 'Premium',
        BusinessSubscriptionTier.pro => 'Standard',
        BusinessSubscriptionTier.basic => 'Basic',
      };

  /// Value stored in `businesses.subscription_tier`.
  String get dbValue => switch (this) {
        BusinessSubscriptionTier.premium => 'premium',
        BusinessSubscriptionTier.pro => 'pro',
        BusinessSubscriptionTier.basic => 'basic',
      };
}

enum BusinessSubscriptionStatus {
  active,
  inactive,
  trialing,
  pastDue,
  canceled,
  unknown,
}

BusinessSubscriptionTier businessTierFromRaw(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'premium':
      return BusinessSubscriptionTier.premium;
    case 'pro':
      return BusinessSubscriptionTier.pro;
    default:
      return BusinessSubscriptionTier.basic;
  }
}

BusinessSubscriptionStatus businessSubscriptionStatusFromRaw(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'active':
      return BusinessSubscriptionStatus.active;
    case 'inactive':
      return BusinessSubscriptionStatus.inactive;
    case 'trialing':
      return BusinessSubscriptionStatus.trialing;
    case 'past_due':
      return BusinessSubscriptionStatus.pastDue;
    case 'canceled':
      return BusinessSubscriptionStatus.canceled;
    default:
      return BusinessSubscriptionStatus.unknown;
  }
}
