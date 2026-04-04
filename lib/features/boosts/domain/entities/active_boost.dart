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

  ActiveBoost copyWith({
    String? id,
    String? typeLabel,
    String? title,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    String? views,
    String? clicks,
    String? calls,
    int? viewsChangePercent,
    int? clicksChangePercent,
    int? callsChangePercent,
    bool? autoRenew,
    String? planLabel,
    String? saves,
    int? savesChangePercent,
  }) {
    return ActiveBoost(
      id: id ?? this.id,
      typeLabel: typeLabel ?? this.typeLabel,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      views: views ?? this.views,
      clicks: clicks ?? this.clicks,
      calls: calls ?? this.calls,
      viewsChangePercent: viewsChangePercent ?? this.viewsChangePercent,
      clicksChangePercent: clicksChangePercent ?? this.clicksChangePercent,
      callsChangePercent: callsChangePercent ?? this.callsChangePercent,
      autoRenew: autoRenew ?? this.autoRenew,
      planLabel: planLabel ?? this.planLabel,
      saves: saves ?? this.saves,
      savesChangePercent: savesChangePercent ?? this.savesChangePercent,
    );
  }

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
