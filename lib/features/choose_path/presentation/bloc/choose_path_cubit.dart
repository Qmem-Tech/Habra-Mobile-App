import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/user.dart';
import 'choose_path_state.dart';

/// Cubit for managing the choose path feature
class ChoosePathCubit extends Cubit<ChoosePathState> {
  ChoosePathCubit() : super(const ChoosePathInitial());

  /// Select a user role
  void selectRole(UserRole role) {
    emit(ChoosePathSelected(role));
  }

  /// Reset selection
  void reset() {
    emit(const ChoosePathInitial());
  }
}
