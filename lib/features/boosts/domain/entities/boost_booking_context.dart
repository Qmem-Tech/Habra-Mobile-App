import 'package:equatable/equatable.dart';

import 'boost_option.dart';

/// Context for the current boost flow: what type and which item(s) selected.
class BoostBookingContext extends Equatable {
  const BoostBookingContext({
    required this.optionType,
    this.selectedLocationId,
    this.selectedLocationName,
    this.selectedDealId,
    this.selectedDealTitle,
    this.selectedDealMerchantName,
    this.selectedDealImageUrl,
    this.selectedDealExpiresInDays,
    this.selectedJobId,
    this.selectedJobTitle,
    this.selectedJobEmployerName,
  });

  final BoostOptionType optionType;
  final String? selectedLocationId;
  final String? selectedLocationName;
  final String? selectedDealId;
  final String? selectedDealTitle;
  final String? selectedDealMerchantName;
  final String? selectedDealImageUrl;
  final String? selectedDealExpiresInDays;
  final String? selectedJobId;
  final String? selectedJobTitle;
  final String? selectedJobEmployerName;

  String get summaryTitle {
    switch (optionType) {
      case BoostOptionType.businessListing:
        return selectedLocationName ?? 'Business Listing';
      case BoostOptionType.deal:
        return selectedDealTitle ?? 'Deal';
      case BoostOptionType.job:
        return selectedJobTitle ?? 'Job';
    }
  }

  @override
  List<Object?> get props => [
        optionType,
        selectedLocationId,
        selectedLocationName,
        selectedDealId,
        selectedDealTitle,
        selectedDealMerchantName,
        selectedDealImageUrl,
        selectedDealExpiresInDays,
        selectedJobId,
        selectedJobTitle,
        selectedJobEmployerName,
      ];
}
