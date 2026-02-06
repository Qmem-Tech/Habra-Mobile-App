import 'package:equatable/equatable.dart';

/// Type of boost: business listing, deal, or job.
enum BoostOptionType {
  businessListing,
  deal,
  job,
}

/// Option shown on "What would you like to boost?" screen.
class BoostOption extends Equatable {
  const BoostOption({
    required this.id,
    required this.type,
    required this.priceLabel,
    required this.title,
    required this.description,
  });

  final String id;
  final BoostOptionType type;
  final String priceLabel;
  final String title;
  final String description;

  @override
  List<Object?> get props => [id, type, priceLabel, title, description];
}
