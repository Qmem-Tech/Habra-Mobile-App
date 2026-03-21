/// Parsed address data for business forms (street, city, state, zip).
class BusinessAddressData {
  const BusinessAddressData({
    this.street,
    this.suite,
    this.city,
    this.state,
    this.zipCode,
    this.latitude,
    this.longitude,
  });

  final String? street;
  final String? suite;
  final String? city;
  final String? state;
  final String? zipCode;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;
}
