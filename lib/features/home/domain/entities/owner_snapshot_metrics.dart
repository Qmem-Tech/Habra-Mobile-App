import 'package:equatable/equatable.dart';

/// Today's or monthly snapshot metrics for business owner (views, clicks, messages).
class OwnerSnapshotMetrics extends Equatable {
  final int views;
  final int clicks;
  final int messages;
  final double viewsChangePercent;
  final double clicksChangePercent;
  final double messagesChangePercent;

  const OwnerSnapshotMetrics({
    required this.views,
    required this.clicks,
    required this.messages,
    this.viewsChangePercent = 0,
    this.clicksChangePercent = 0,
    this.messagesChangePercent = 0,
  });

  String get viewsFormatted => _formatCount(views);
  String get clicksFormatted => _formatCount(clicks);
  String get messagesFormatted => _formatCount(messages);

  static String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  @override
  List<Object?> get props => [
        views,
        clicks,
        messages,
        viewsChangePercent,
        clicksChangePercent,
        messagesChangePercent,
      ];
}
