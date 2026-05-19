import 'business_subscription_policy.dart';
import 'business_subscription_tier.dart';

/// How gallery URLs behave when a listing has more photos than the current plan allows.
///
/// Extra URLs stay in `businesses.image_urls`; they are hidden from customers and
/// shown blurred to the owner until they upgrade or remove them.
class BusinessGalleryAccess {
  const BusinessGalleryAccess._();

  static int activeLimit(BusinessSubscriptionTier tier) =>
      BusinessSubscriptionPolicy.maxGalleryImages(tier);

  static bool isLockedIndex(int index, BusinessSubscriptionTier tier) =>
      index >= activeLimit(tier);

  /// First [activeLimit] gallery URLs — used on Explore / business detail (community).
  static List<String> urlsForPublic(
    List<String> galleryUrls,
    BusinessSubscriptionTier tier,
  ) {
    if (galleryUrls.isEmpty) return galleryUrls;
    final limit = activeLimit(tier);
    if (galleryUrls.length <= limit) return galleryUrls;
    return galleryUrls.sublist(0, limit);
  }

  static int lockedCount(
    List<String> galleryUrls,
    BusinessSubscriptionTier tier,
  ) {
    final limit = activeLimit(tier);
    if (galleryUrls.length <= limit) return 0;
    return galleryUrls.length - limit;
  }
}
