import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/feedback_ticket.dart';
import '../../domain/usecases/list_feedback_for_admin_usecase.dart';
import '../../domain/usecases/update_admin_feedback_usecase.dart';
import 'admin_feedback_state.dart';

class AdminFeedbackCubit extends Cubit<AdminFeedbackState> {
  AdminFeedbackCubit({
    required this.listUseCase,
    required this.updateUseCase,
  }) : super(AdminFeedbackInitial());

  final ListFeedbackForAdminUseCase listUseCase;
  final UpdateAdminFeedbackUseCase updateUseCase;

  Future<void> load() async {
    emit(AdminFeedbackLoading());
    final result = await listUseCase();
    result.fold(
      (f) => emit(AdminFeedbackError(f.message)),
      (items) => emit(AdminFeedbackLoaded(items)),
    );
  }

  Future<String?> updateTicket({
    required String id,
    required FeedbackTicketStatus status,
    String? adminNotes,
  }) async {
    final result = await updateUseCase(
      id: id,
      status: status,
      adminNotes: adminNotes,
    );
    return result.fold<Future<String?>>(
      (f) async => f.message,
      (_) async {
        await load();
        return null;
      },
    );
  }
}
