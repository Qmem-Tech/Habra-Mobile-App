import 'package:equatable/equatable.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/job.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Event> events;
  final List<Deal> deals;
  final List<Business> businesses;
  final List<Job> jobs;

  /// Set when the corresponding feed failed; UI can show a section-level message.
  final String? eventsError;
  final String? dealsError;
  final String? businessesError;
  final String? jobsError;

  const HomeLoaded({
    required this.events,
    required this.deals,
    required this.businesses,
    required this.jobs,
    this.eventsError,
    this.dealsError,
    this.businessesError,
    this.jobsError,
  });

  @override
  List<Object?> get props => [
        events,
        deals,
        businesses,
        jobs,
        eventsError,
        dealsError,
        businessesError,
        jobsError,
      ];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
