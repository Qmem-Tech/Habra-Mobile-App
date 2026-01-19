import 'package:equatable/equatable.dart';
import '../../domain/entities/business_list_item.dart';
import '../../domain/entities/business_detail.dart';
import '../../domain/entities/business_filters.dart';

abstract class BusinessesState extends Equatable {
  const BusinessesState();

  @override
  List<Object?> get props => [];
}

class BusinessesInitial extends BusinessesState {}

class BusinessesLoading extends BusinessesState {}

class BusinessesLoaded extends BusinessesState {
  final List<BusinessListItem> businesses;
  final BusinessFilters? activeFilters;
  final String? searchQuery;

  const BusinessesLoaded({
    required this.businesses,
    this.activeFilters,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [businesses, activeFilters, searchQuery];
}

class BusinessesError extends BusinessesState {
  final String message;

  const BusinessesError(this.message);

  @override
  List<Object?> get props => [message];
}

// Business Detail States
class BusinessDetailInitial extends BusinessesState {}

class BusinessDetailLoading extends BusinessesState {}

class BusinessDetailLoaded extends BusinessesState {
  final BusinessDetail business;

  const BusinessDetailLoaded(this.business);

  @override
  List<Object?> get props => [business];
}

class BusinessDetailError extends BusinessesState {
  final String message;

  const BusinessDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
