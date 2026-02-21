import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/saved_item.dart';
import '../../domain/usecases/get_saved_items_usecase.dart';
import '../../domain/usecases/remove_saved_item_usecase.dart';
import 'saved_items_state.dart';

class SavedItemsCubit extends Cubit<SavedItemsState> {
  final GetSavedItemsUseCase getSavedItemsUseCase;
  final RemoveSavedItemUseCase removeSavedItemUseCase;

  SavedItemsCubit({
    required this.getSavedItemsUseCase,
    required this.removeSavedItemUseCase,
  }) : super(SavedItemsInitial());

  Future<void> loadSavedItems({SavedItemType? filterType}) async {
    emit(SavedItemsLoading());

    final result = await getSavedItemsUseCase(filterType: filterType);
    result.fold(
      (failure) => emit(SavedItemsError(failure.message)),
      (items) => emit(SavedItemsLoaded(items: items, filterType: filterType)),
    );
  }

  Future<void> removeItem(String savedItemId) async {
    final current = state;
    if (current is! SavedItemsLoaded) return;

    final result = await removeSavedItemUseCase(savedItemId);
    result.fold(
      (_) => {},
      (_) {
        final updated = current.items.where((i) => i.id != savedItemId).toList();
        emit(SavedItemsLoaded(items: updated, filterType: current.filterType));
      },
    );
  }
}
