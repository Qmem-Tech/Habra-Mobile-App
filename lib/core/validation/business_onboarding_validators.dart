/// Shared validators for business onboarding flows (name, address, contact).
class BusinessOnboardingValidators {
  BusinessOnboardingValidators._();

  static const int businessNameMinLength = 2;
  static const int businessNameMaxLength = 120;

  static String? businessName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Please enter your business name';
    }
    if (v.length < businessNameMinLength) {
      return 'Business name must be at least $businessNameMinLength characters';
    }
    if (v.length > businessNameMaxLength) {
      return 'Business name must be $businessNameMaxLength characters or fewer';
    }
    return null;
  }

  static String? street(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Please enter street address';
    }
    return null;
  }

  static String? city(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Please enter city';
    }
    if (v.length > 80) {
      return 'City name is too long';
    }
    return null;
  }

  static String? stateUs(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Please enter state';
    }
    if (v.length < 2) {
      return 'Please enter a valid state';
    }
    return null;
  }

  static String? zipUs(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Please enter ZIP code';
    }
    if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(v)) {
      return 'Please enter a valid ZIP code';
    }
    return null;
  }

  /// Returns null if valid, otherwise an error message (for SnackBar / inline).
  static String? locationFields({
    required String street,
    required String city,
    required String state,
    required String zip,
  }) {
    return street.trim().isEmpty
        ? 'Please enter street address'
        : city.trim().isEmpty
            ? 'Please enter city'
            : state.trim().isEmpty
                ? 'Please enter state'
                : state.trim().length < 2
                    ? 'Please enter a valid state'
                    : zip.trim().isEmpty
                        ? 'Please enter ZIP code'
                        : !RegExp(r'^\d{5}(-\d{4})?$').hasMatch(zip.trim())
                            ? 'Please enter a valid ZIP code'
                            : null;
  }
}
