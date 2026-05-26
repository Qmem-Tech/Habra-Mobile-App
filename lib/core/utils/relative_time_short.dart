/// Compact relative time for UI badges (e.g. reviews, jobs).
///
/// Uses [dt] in local time vs device clock. Future or same-second times show
/// "Just now" instead of "0m ago".
String formatShortTimeAgo(DateTime dt) {
  final now = DateTime.now();
  final local = dt.isUtc ? dt.toLocal() : dt;
  final diff = now.difference(local);
  if (diff.isNegative) return 'Just now';
  if (diff.inSeconds < 45) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${local.month}/${local.day}/${local.year}';
}
