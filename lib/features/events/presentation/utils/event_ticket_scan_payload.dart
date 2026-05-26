/// Parses a scanned QR/string into a ticket UUID when possible.
String? ticketIdFromScanPayload(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final uuid = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  ).firstMatch(trimmed)?.group(0);
  if (uuid != null) return uuid;

  if (trimmed.length == 36 && trimmed.contains('-')) return trimmed;
  return null;
}
