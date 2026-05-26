import 'business_subscription_tier.dart';

/// Open job posts (`jobs.status = open`) per business. Kept top-level so call sites
/// do not depend on incremental cache for class statics.
int maxOpenJobPostsForSubscriptionTier(BusinessSubscriptionTier tier) {
  switch (tier) {
    case BusinessSubscriptionTier.basic:
      return 0;
    case BusinessSubscriptionTier.pro:
      return 5;
    case BusinessSubscriptionTier.premium:
      return 9999;
  }
}

class BusinessSubscriptionPolicy {
  const BusinessSubscriptionPolicy._();

  /// Free / basic listing: profile + search only — no deals, events, or job posts.
  static bool isFreeListingOnlyTier(BusinessSubscriptionTier tier) =>
      tier == BusinessSubscriptionTier.basic;

  /// Deals, hosted events, and job posts require Standard or Premium.
  static bool canPostDealsEventsJobs(BusinessSubscriptionTier tier) =>
      !isFreeListingOnlyTier(tier);

  static bool canAccessAnalytics(BusinessSubscriptionTier tier) =>
      tier != BusinessSubscriptionTier.basic;

  static bool canUseVerifiedBadge(BusinessSubscriptionTier tier) =>
      tier != BusinessSubscriptionTier.basic;

  static int maxActiveDeals(BusinessSubscriptionTier tier) {
    switch (tier) {
      case BusinessSubscriptionTier.basic:
        return 0;
      case BusinessSubscriptionTier.pro:
        return 5;
      case BusinessSubscriptionTier.premium:
        return 9999;
    }
  }

  static int maxActiveEvents(BusinessSubscriptionTier tier) {
    switch (tier) {
      case BusinessSubscriptionTier.basic:
        return 0;
      case BusinessSubscriptionTier.pro:
        return 5;
      case BusinessSubscriptionTier.premium:
        return 9999;
    }
  }

  /// Concurrent **open** job listings (`jobs.status = open`) per business.
  static int maxActiveJobs(BusinessSubscriptionTier tier) =>
      maxOpenJobPostsForSubscriptionTier(tier);

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

  /// Gallery photo limit per listing.
  /// Basic = 3, Standard (Pro) = 8, Premium = 15.
  static int maxGalleryImages(BusinessSubscriptionTier tier) {
    switch (tier) {
      case BusinessSubscriptionTier.basic:
        return 3;
      case BusinessSubscriptionTier.pro:
        return 8;
      case BusinessSubscriptionTier.premium:
        return 15;
    }
  }
}
