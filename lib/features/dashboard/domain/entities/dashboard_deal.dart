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
  });

  String get expiryDateShort {
    if (expiryDate == null) return '';
    final d = expiryDate!;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
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
      ];
}
