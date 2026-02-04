import 'package:equatable/equatable.dart';

enum DashboardDealStatus { active, expired, draft }

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

  const DashboardDeal({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.dealTypeLabel,
    required this.validityDescription,
    required this.redeemedCount,
    this.expiryDate,
    this.status = DashboardDealStatus.active,
    this.merchantName,
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
        title,
        description,
        imageUrl,
        dealTypeLabel,
        validityDescription,
        redeemedCount,
        expiryDate,
        status,
        merchantName,
      ];

  String get expiryDateShort {
    if (expiryDate == null) return '';
    final d = expiryDate!;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}
