import 'package:intl/intl.dart';

/// Labels for boost plan cards (duration line + auto-renew subtitle).
abstract final class BoostPlanDisplay {
  BoostPlanDisplay._();

  /// Short headline from [durationWeeks]: weeks when ≤8, otherwise rounded months.
  static String durationHeadline(int durationWeeks) {
    final w = durationWeeks < 1 ? 1 : durationWeeks;
    if (w <= 8) {
      if (w == 1) return '1 Week Boost';
      return '$w Weeks Boost';
    }
    final months = (w / 4.0).round().clamp(1, 48);
    if (months == 1) return '1 Month Boost';
    return '$months Months Boost';
  }

  /// Shown under the auto-renew switch (next billing period start).
  static String autoRenewCaption(DateTime from, int durationWeeks) {
    final w = durationWeeks < 1 ? 1 : durationWeeks;
    final next = from.add(Duration(days: w * 7));
    return 'Renews on ${DateFormat('MMM d').format(next)}';
  }
}
