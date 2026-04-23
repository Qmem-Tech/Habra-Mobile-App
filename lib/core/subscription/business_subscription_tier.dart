enum BusinessSubscriptionTier {
  basic,
  pro,
  premium,
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
