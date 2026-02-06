import 'package:equatable/equatable.dart';

import 'boost_option.dart';

/// Past boost item for "Past Boosts" list with re-boost action.
class PastBoost extends Equatable {
  const PastBoost({
    required this.id,
    required this.type,
    required this.title,
    required this.dateRange,
    required this.views,
  });

  final String id;
  final BoostOptionType type;
  final String title;
  final String dateRange;
  final String views;

  @override
  List<Object?> get props => [id, type, title, dateRange, views];
}
