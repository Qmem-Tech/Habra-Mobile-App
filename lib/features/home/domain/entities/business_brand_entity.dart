import 'package:equatable/equatable.dart';

/// A business brand (parent business) for "Add New Location" flow.
/// Used on Choose Business Brand screen.
class BusinessBrandEntity extends Equatable {
  final String id;
  final String name;
  final int activeLocationsCount;
  final String? logoUrl;

  const BusinessBrandEntity({
    required this.id,
    required this.name,
    required this.activeLocationsCount,
    this.logoUrl,
  });

  String get activeLocationsLabel =>
      activeLocationsCount == 1 ? '1 Active Location' : '$activeLocationsCount Active Locations';

  @override
  List<Object?> get props => [id, name, activeLocationsCount, logoUrl];
}
