import 'package:equatable/equatable.dart';

enum SetupTaskId {
  completeProfile,
  postFirstDeal,
  shareListing,
}

/// A setup/to-do task for business owner onboarding.
class SetupTask extends Equatable {
  final SetupTaskId id;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isLocked;
  final String? actionLabel;
  final int order;

  const SetupTask({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.isLocked = false,
    this.actionLabel,
    this.order = 0,
  });

  @override
  List<Object?> get props => [id, title, description, isCompleted, isLocked, actionLabel, order];
}
