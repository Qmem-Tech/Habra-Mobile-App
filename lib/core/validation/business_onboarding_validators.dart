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

  /// Best-effort 2-letter code: strips non-letters, uses first two A-Z (e.g. California -> CA).
  /// Save with this when persisting so the API gets a short code after geocoding.
  static String? normalizeStateToAbbrev(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    final letters = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (letters.isEmpty) return null;
    return letters.length >= 2 ? letters.substring(0, 2) : letters;
  }

  /// Two-letter US state (typed or from geocoder text).
  static String? stateUsAbbrev(String? value) {
    final abbrev = normalizeStateToAbbrev(value);
    if (abbrev == null || abbrev.isEmpty) {
      return 'Please enter state';
    }
    if (abbrev.length != 2) {
      return 'Use a 2-letter state code (e.g. AL, CA)';
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

  // ---------------------------------------------------------------------------
  // Contact details (business registration step 3)
  // ---------------------------------------------------------------------------

  /// [completeNumber] as from intl_phone_field (`phone.completeNumber`).
  static String? businessPhone(String completeNumber) {
    final digits = completeNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'Please enter phone number';
    }
    if (digits.length < 10) {
      return 'Please enter a valid phone number (at least 10 digits)';
    }
    if (digits.length > 15) {
      return 'Phone number is too long';
    }
    return null;
  }

  static String? businessEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Please enter business email';
    }
    if (v.length > 254) {
      return 'Email is too long';
    }
    final re = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(v)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Empty is allowed. Otherwise require http(s) and a non-empty host.
  static String? businessWebsiteOptional(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    var uri = Uri.tryParse(v);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Enter a valid URL (https://example.com)';
    }
    if (uri.host.isEmpty) {
      return 'Enter a valid website address including the domain name';
    }
    return null;
  }

  static int _hhmmToMinutes(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p.isNotEmpty ? p[0] : '') ?? 0;
    final m = p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0;
    return h * 60 + m;
  }

  /// At least one open day; closing after opening (registration uses one pair for all open days).
  static String? registrationBusinessHours({
    required List<bool> dayClosed,
    required String openingTime,
    required String closingTime,
  }) {
    if (!dayClosed.contains(false)) {
      return 'Select at least one day your business is open (use Edit Hours)';
    }
    final openM = _hhmmToMinutes(openingTime);
    final closeM = _hhmmToMinutes(closingTime);
    if (openM >= closeM) {
      return 'Closing time must be after opening time (use Edit Hours)';
    }
    return null;
  }
}
