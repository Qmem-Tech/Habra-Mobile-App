import 'package:equatable/equatable.dart';

enum ListingStatusType {
  pending,
  verified,
}

/// Listing status for a business (verification pending or verified).
class ListingStatusEntity extends Equatable {
  final String businessId;
  final String businessName;
  final String? locationText;
  final String imageUrl;
  final ListingStatusType status;
  final bool isNewBusiness;

  const ListingStatusEntity({
    required this.businessId,
    required this.businessName,
    this.locationText,
    required this.imageUrl,
    required this.status,
    this.isNewBusiness = false,
  });

  bool get isVerified => status == ListingStatusType.verified;
  bool get isPending => status == ListingStatusType.pending;

  @override
  List<Object?> get props => [businessId, businessName, locationText, imageUrl, status, isNewBusiness];
}
