import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_happening_this_week_usecase.dart';
import '../../domain/usecases/get_hot_deals_usecase.dart';
import '../../domain/usecases/get_popular_businesses_usecase.dart';
import '../../domain/usecases/get_latest_jobs_usecase.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/job.dart';
import '../../domain/home_feed_location.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetHappeningThisWeekUseCase getHappeningThisWeekUseCase;
  final GetHotDealsUseCase getHotDealsUseCase;
  final GetPopularBusinessesUseCase getPopularBusinessesUseCase;
  final GetLatestJobsUseCase getLatestJobsUseCase;

  HomeCubit({
    required this.getHappeningThisWeekUseCase,
    required this.getHotDealsUseCase,
    required this.getPopularBusinessesUseCase,
    required this.getLatestJobsUseCase,
  }) : super(HomeInitial());

  Future<void> loadHomeData(HomeFeedLocation location) async {
    emit(HomeLoading());

    try {
      // Load all data in parallel
      final results = await Future.wait([
        getHappeningThisWeekUseCase(location),
        getHotDealsUseCase(location),
        getPopularBusinessesUseCase(location),
        getLatestJobsUseCase(location),
      ]);

      final events = results[0].fold<List<Event>>(
        (l) => <Event>[],
        (r) => r as List<Event>,
      );
      final deals = results[1].fold<List<Deal>>(
        (l) => <Deal>[],
        (r) => r as List<Deal>,
      );
      final businesses = results[2].fold<List<Business>>(
        (l) => <Business>[],
        (r) => r as List<Business>,
      );
      final jobs = results[3].fold<List<Job>>(
        (l) => <Job>[],
        (r) => r as List<Job>,
      );

      emit(HomeLoaded(
        events: events,
        deals: deals,
        businesses: businesses,
        jobs: jobs,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
