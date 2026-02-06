import 'package:equatable/equatable.dart';

/// Active boost item (e.g. Premium Business Listing with metrics).
class ActiveBoost extends Equatable {
  const ActiveBoost({
    required this.id,
    required this.typeLabel,
    required this.title,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.views,
    required this.clicks,
    required this.calls,
    required this.viewsChangePercent,
    required this.clicksChangePercent,
    required this.callsChangePercent,
    required this.autoRenew,
    this.planLabel,
    this.saves,
    this.savesChangePercent,
  });

  final String id;
  final String typeLabel;
  final String title;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final String views;
  final String clicks;
  final String calls;
  final int viewsChangePercent;
  final int clicksChangePercent;
  final int callsChangePercent;
  final bool autoRenew;
  final String? planLabel;
  /// Optional for detail page (e.g. "Saves" metric).
  final String? saves;
  final int? savesChangePercent;

  String get dateRangeText {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final s = '${months[startDate.month - 1]} ${startDate.day}';
    final e = '${months[endDate.month - 1]} ${endDate.day}, ${endDate.year}';
    return 'Started $s • Running until $e';
  }

  int get remainingDays => endDate.difference(DateTime.now()).inDays.clamp(0, 999);

  @override
  List<Object?> get props => [
        id,
        typeLabel,
        title,
        imageUrl,
        startDate,
        endDate,
        views,
        clicks,
        calls,
        viewsChangePercent,
        clicksChangePercent,
        callsChangePercent,
        autoRenew,
        planLabel,
        saves,
        savesChangePercent,
      ];
}
