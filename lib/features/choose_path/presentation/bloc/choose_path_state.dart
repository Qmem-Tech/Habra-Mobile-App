import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user.dart';

/// States for the Choose Path feature
abstract class ChoosePathState extends Equatable {
  const ChoosePathState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no role selected
class ChoosePathInitial extends ChoosePathState {
  const ChoosePathInitial();
}

/// A role has been selected
class ChoosePathSelected extends ChoosePathState {
  final UserRole selectedRole;

  const ChoosePathSelected(this.selectedRole);

  @override
  List<Object?> get props => [selectedRole];
}
