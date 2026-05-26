import 'package:equatable/equatable.dart';

enum DashboardDealStatus { active, expired, draft, inactive }

/// Deal as shown on business owner dashboard (with status, redemption count, expiry).
class DashboardDeal extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String dealTypeLabel;
  final String validityDescription;
  final int redeemedCount;
  final DateTime? expiryDate;
  final DashboardDealStatus status;
  /// Business/merchant name for display (e.g. in Select Deal to Boost, Order Confirmation).
  final String? merchantName;
  /// Owning business (required for `boosts.business_id` when boosting this deal).
  final String businessId;

  /// Raw DB `category` (`percent_off` \| `fixed_amount` \| `free_item`) for edit form.
  final String? category;
  final int? discountPercentage;
  final int? discountedPrice;
  final DateTime? validFrom;

  const DashboardDeal({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.dealTypeLabel,
    required this.validityDescription,
    required this.redeemedCount,
    this.expiryDate,
    this.status = DashboardDealStatus.active,
    this.merchantName,
    this.category,
    this.discountPercentage,
    this.discountedPrice,
    this.validFrom,
  });

  /// "Expires in X days" for display.
  String get expiresInDays {
    if (expiryDate == null) return '';
    final diff = expiryDate!.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'Expired';
    return 'Expires in $diff days';
  }

  @override
  List<Object?> get props => [
        id,
        businessId,
        title,
        description,
        imageUrl,
        dealTypeLabel,
        validityDescription,
        redeemedCount,
        expiryDate,
        status,
        merchantName,
        category,
        discountPercentage,
        discountedPrice,
        validFrom,
      ];

  String get expiryDateShort {
    if (expiryDate == null) return '';
    final d = expiryDate!;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}
