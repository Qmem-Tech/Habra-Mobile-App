import 'package:equatable/equatable.dart';

/// Result of redeeming a deal; [id] is the DB row (proof), [code] is staff-facing.
class DealRedemption extends Equatable {
  final String id;
  final String code;

  const DealRedemption({required this.id, required this.code});

  @override
  List<Object?> get props => [id, code];
}
