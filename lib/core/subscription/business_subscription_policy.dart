import 'business_subscription_tier.dart';

class BusinessSubscriptionPolicy {
  const BusinessSubscriptionPolicy._();

  static bool canAccessAnalytics(BusinessSubscriptionTier tier) =>
      tier != BusinessSubscriptionTier.basic;

  static bool canUseVerifiedBadge(BusinessSubscriptionTier tier) =>
      tier != BusinessSubscriptionTier.basic;

  static int maxActiveDeals(BusinessSubscriptionTier tier) {
    switch (tier) {
      case BusinessSubscriptionTier.basic:
        return 1;
      case BusinessSubscriptionTier.pro:
        return 5;
      case BusinessSubscriptionTier.premium:
        return 9999;
    }
  }

  static int maxActiveEvents(BusinessSubscriptionTier tier) {
    switch (tier) {
      case BusinessSubscriptionTier.basic:
        return 1;
      case BusinessSubscriptionTier.pro:
        return 3;
      case BusinessSubscriptionTier.premium:
        return 9999;
    }
  }

  static int feedBoostWeight(BusinessSubscriptionTier tier) {
    switch (tier) {
      case BusinessSubscriptionTier.basic:
        return 0;
      case BusinessSubscriptionTier.pro:
        return 1;
      case BusinessSubscriptionTier.premium:
        return 2;
    }
  }
}
