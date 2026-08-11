import 'package:flutter/material.dart';

import '../../domain/entities/business_detail.dart';
import 'listing_map_preview.dart';

/// Small map preview for business listings: DB coordinates or forward-geocoded address.
class BusinessMapPreview extends StatelessWidget {
  const BusinessMapPreview({
    super.key,
    required this.business,
    this.height = 150,
    this.showDirectionsButton = true,
  });

  final BusinessDetail business;
  final double height;
  final bool showDirectionsButton;

  @override
  Widget build(BuildContext context) {
    final subtitle = business.categories.isNotEmpty
        ? '${business.categories.first.displayName} • ${business.rating.toStringAsFixed(1)} (${business.reviewCount})'
        : null;
    return ListingMapPreview(
      listingId: business.id,
      name: business.name,
      fullAddress: business.fullAddress,
      latitude: business.latitude,
      longitude: business.longitude,
      subtitle: subtitle,
      height: height,
      showDirectionsButton: showDirectionsButton,
    );
  }
}
