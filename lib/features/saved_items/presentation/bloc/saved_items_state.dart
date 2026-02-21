import 'package:equatable/equatable.dart';
import '../../domain/entities/saved_item.dart';

abstract class SavedItemsState extends Equatable {
  const SavedItemsState();

  @override
  List<Object?> get props => [];
}

class SavedItemsInitial extends SavedItemsState {}

class SavedItemsLoading extends SavedItemsState {}

class SavedItemsLoaded extends SavedItemsState {
  final List<SavedItem> items;
  final SavedItemType? filterType;

  const SavedItemsLoaded({required this.items, this.filterType});

  @override
  List<Object?> get props => [items, filterType];
}

class SavedItemsError extends SavedItemsState {
  final String message;

  const SavedItemsError(this.message);

  @override
  List<Object?> get props => [message];
}
