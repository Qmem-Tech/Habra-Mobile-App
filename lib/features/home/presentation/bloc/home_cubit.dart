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
      String? eventsError;
      String? dealsError;
      String? businessesError;
      String? jobsError;

      final eventsRes = await getHappeningThisWeekUseCase(location);
      final events = eventsRes.fold<List<Event>>((l) {
        eventsError = l.message;
        return <Event>[];
      }, (r) => r);

      final dealsRes = await getHotDealsUseCase(location);
      final deals = dealsRes.fold<List<Deal>>((l) {
        dealsError = l.message;
        return <Deal>[];
      }, (r) => r);

      final businessesRes = await getPopularBusinessesUseCase(location);
      final businesses = businessesRes.fold<List<Business>>((l) {
        businessesError = l.message;
        return <Business>[];
      }, (r) => r);

      final jobsRes = await getLatestJobsUseCase(location);
      final jobs = jobsRes.fold<List<Job>>((l) {
        jobsError = l.message;
        return <Job>[];
      }, (r) => r);

      emit(HomeLoaded(
        events: events,
        deals: deals,
        businesses: businesses,
        jobs: jobs,
        eventsError: eventsError,
        dealsError: dealsError,
        businessesError: businessesError,
        jobsError: jobsError,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
