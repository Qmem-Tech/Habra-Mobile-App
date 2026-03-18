import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/create_event_data.dart';
import '../../domain/usecases/create_event_usecase.dart';
import 'create_event_state.dart';

class CreateEventCubit extends Cubit<CreateEventState> {
  CreateEventCubit(this._createEventUseCase) : super(CreateEventInitial());

  final CreateEventUseCase _createEventUseCase;

  Future<void> createEvent(CreateEventData data) async {
    emit(CreateEventLoading());

    final result = await _createEventUseCase(data);

    result.fold(
      (failure) => emit(CreateEventError(failure.message)),
      (event) => emit(CreateEventSuccess(event)),
    );
  }
}
