/// Storefront image limits (logo / cover / gallery on `businesses`).
abstract final class BusinessMediaLimits {
  BusinessMediaLimits._();

  /// Extra descriptive photos stored in `businesses.image_urls` (optional).
  static const int maxGalleryImages = 5;
}
