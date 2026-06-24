/// Formats stored business hours (`HH:mm` or `HH:mm:ss`) for display as 12-hour time.
String formatBusinessTimeHmToAmPm(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.isEmpty) return hhmm;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
  final amPm = h < 12 ? 'AM' : 'PM';
  return '$hour12:${m.toString().padLeft(2, '0')} $amPm';
}
