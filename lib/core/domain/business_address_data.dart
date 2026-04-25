/// Parsed address data for business forms (street, city, state, zip).
class BusinessAddressData {
  const BusinessAddressData({
    this.name,
    this.street,
    this.suite,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.placeId,
    this.formattedAddress,
    this.googleMapsUrl,
  });

  final String? name;
  final String? street;
  final String? suite;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final String? formattedAddress;
  final String? googleMapsUrl;

  bool get hasCoordinates => latitude != null && longitude != null;

  Map<String, dynamic> toLocationPayload({String? fallbackName}) {
    return {
      'name': name ?? fallbackName,
      'address_line1': street,
      'address_line2': suite,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'place_id': placeId,
      'google_maps_url': googleMapsUrl,
    }..removeWhere((_, value) => value == null || value == '');
  }
}
