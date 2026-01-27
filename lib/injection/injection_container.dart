import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/network/network_info.dart';
import '../core/storage/local_storage.dart';
import '../core/theme/theme_cubit.dart';
import '../core/localization/localization_cubit.dart';
import '../core/network/firebase/firebase_services.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/datasources/auth_local_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/register_usecase.dart';
import '../features/auth/domain/usecases/login_as_guest_usecase.dart';
import '../features/auth/domain/usecases/sign_in_with_google_usecase.dart';

// Splash feature
import '../features/splash/data/repositories/splash_repository_impl.dart';
import '../features/splash/domain/repositories/splash_repository.dart';
import '../features/splash/domain/usecases/get_splash_status_usecase.dart';

// Onboarding feature
import '../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../features/onboarding/domain/usecases/complete_onboarding_usecase.dart';

// Home feature
import '../features/home/data/datasources/home_remote_datasource.dart';
import '../features/home/data/datasources/search_remote_datasource.dart';
import '../features/home/data/datasources/search_local_datasource.dart';
import '../features/home/data/datasources/notification_remote_datasource.dart';
import '../features/home/data/repositories/home_repository_impl.dart';
import '../features/home/data/repositories/search_repository_impl.dart';
import '../features/home/data/repositories/notification_repository_impl.dart';
import '../features/home/domain/repositories/home_repository.dart';
import '../features/home/domain/repositories/search_repository.dart';
import '../features/home/domain/repositories/notification_repository.dart';
import '../features/home/domain/usecases/get_happening_this_week_usecase.dart';
import '../features/home/domain/usecases/get_hot_deals_usecase.dart';
import '../features/home/domain/usecases/get_popular_businesses_usecase.dart';
import '../features/home/domain/usecases/get_latest_jobs_usecase.dart';
import '../features/home/domain/usecases/search_usecase.dart';
import '../features/home/domain/usecases/get_notifications_usecase.dart';
import '../features/home/presentation/bloc/home_cubit.dart';
import '../features/home/presentation/bloc/search_cubit.dart';
import '../features/home/presentation/bloc/notification_cubit.dart';

// Events feature
import '../features/events/data/datasources/events_remote_datasource.dart';
import '../features/events/data/repositories/events_repository_impl.dart';
import '../features/events/domain/repositories/events_repository.dart';
import '../features/events/domain/usecases/get_events_usecase.dart';
import '../features/events/domain/usecases/get_event_detail_usecase.dart';
import '../features/events/domain/usecases/get_user_tickets_usecase.dart';
import '../features/events/domain/usecases/create_order_usecase.dart';
import '../features/events/domain/usecases/process_payment_usecase.dart';
import '../features/events/presentation/bloc/events_cubit.dart';
import '../features/events/presentation/bloc/tickets_cubit.dart';

// Explore feature
import '../features/explore/data/datasources/businesses_remote_datasource.dart';
import '../features/explore/data/repositories/businesses_repository_impl.dart';
import '../features/explore/domain/repositories/businesses_repository.dart';
import '../features/explore/domain/usecases/get_businesses_usecase.dart';
import '../features/explore/domain/usecases/get_business_detail_usecase.dart';
import '../features/explore/domain/usecases/get_deals_usecase.dart';
import '../features/explore/domain/usecases/get_deal_detail_usecase.dart';
import '../features/explore/domain/usecases/get_business_reviews_usecase.dart';
import '../features/explore/domain/usecases/write_review_usecase.dart';
import '../features/explore/domain/usecases/redeem_deal_usecase.dart';
import '../features/explore/presentation/bloc/businesses_cubit.dart';
import '../features/explore/presentation/bloc/deals_cubit.dart';
import '../features/explore/presentation/bloc/reviews_cubit.dart';

// Jobs feature
import '../features/jobs/data/datasources/jobs_remote_datasource.dart';
import '../features/jobs/data/datasources/jobs_local_datasource.dart';
import '../features/jobs/data/datasources/job_applications_remote_datasource.dart';
import '../features/jobs/data/repositories/jobs_repository_impl.dart';
import '../features/jobs/data/repositories/job_applications_repository_impl.dart';
import '../features/jobs/domain/repositories/jobs_repository.dart';
import '../features/jobs/domain/repositories/job_applications_repository.dart';
import '../features/jobs/domain/usecases/get_jobs_usecase.dart';
import '../features/jobs/domain/usecases/get_job_detail_usecase.dart';
import '../features/jobs/domain/usecases/toggle_bookmark_usecase.dart';
import '../features/jobs/domain/usecases/get_job_categories_usecase.dart';
import '../features/jobs/domain/usecases/submit_application_usecase.dart';
import '../features/jobs/domain/usecases/get_applications_usecase.dart';
import '../features/jobs/presentation/bloc/jobs_cubit.dart';
import '../features/jobs/presentation/bloc/job_applications_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => Connectivity());

  // Core
  sl.registerLazySingleton<LocalStorage>(
    () => LocalStorageImpl(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton(() => ApiClient(sl<LocalStorage>()));
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl<Connectivity>()),
  );

  // Theme & Localization
  sl.registerFactory(() => ThemeCubit(localStorage: sl<LocalStorage>()));
  sl.registerFactory(() => LocalizationCubit(localStorage: sl<LocalStorage>()));

  // Features - Auth
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(FirebaseServices()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl<LocalStorage>()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LoginAsGuestUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl<AuthRepository>()));

  // Features - Splash
  sl.registerLazySingleton<SplashRepository>(
    () => SplashRepositoryImpl(
      localStorage: sl<LocalStorage>(),
      firebaseServices: FirebaseServices(),
    ),
  );
  sl.registerLazySingleton(() => GetSplashStatusUseCase(sl<SplashRepository>()));

  // Features - Onboarding
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(
      localStorage: sl<LocalStorage>(),
    ),
  );
  sl.registerLazySingleton(() => CompleteOnboardingUseCase(sl<OnboardingRepository>()));

  // Features - Home
  // Data sources
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<SearchLocalDataSource>(
    () => SearchLocalDataSourceImpl(sl<LocalStorage>()),
  );
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(),
  );

  // Repositories
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(sl<HomeRemoteDataSource>()),
  );
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(
      sl<SearchRemoteDataSource>(),
      sl<SearchLocalDataSource>(),
    ),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl<NotificationRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetHappeningThisWeekUseCase(sl<HomeRepository>()));
  sl.registerLazySingleton(() => GetHotDealsUseCase(sl<HomeRepository>()));
  sl.registerLazySingleton(() => GetPopularBusinessesUseCase(sl<HomeRepository>()));
  sl.registerLazySingleton(() => GetLatestJobsUseCase(sl<HomeRepository>()));
  sl.registerLazySingleton(() => SearchUseCase(sl<SearchRepository>()));
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl<NotificationRepository>()));

  // Cubits (Factory - new instance per usage)
  sl.registerFactory(() => HomeCubit(
    getHappeningThisWeekUseCase: sl<GetHappeningThisWeekUseCase>(),
    getHotDealsUseCase: sl<GetHotDealsUseCase>(),
    getPopularBusinessesUseCase: sl<GetPopularBusinessesUseCase>(),
    getLatestJobsUseCase: sl<GetLatestJobsUseCase>(),
  ));
  sl.registerFactory(() => SearchCubit(
    searchUseCase: sl<SearchUseCase>(),
    searchRepository: sl<SearchRepository>(),
  ));
  sl.registerFactory(() => NotificationCubit(
    getNotificationsUseCase: sl<GetNotificationsUseCase>(),
    notificationRepository: sl<NotificationRepository>(),
  ));

  // Features - Events
  // Data sources
  sl.registerLazySingleton<EventsRemoteDataSource>(
    () => EventsRemoteDataSourceImpl(),
  );

  // Repositories
  sl.registerLazySingleton<EventsRepository>(
    () => EventsRepositoryImpl(sl<EventsRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetEventsUseCase(sl<EventsRepository>()));
  sl.registerLazySingleton(() => GetEventDetailUseCase(sl<EventsRepository>()));
  sl.registerLazySingleton(() => GetUserTicketsUseCase(sl<EventsRepository>()));
  sl.registerLazySingleton(() => CreateOrderUseCase(sl<EventsRepository>()));
  sl.registerLazySingleton(() => ProcessPaymentUseCase(sl<EventsRepository>()));

  // Cubits
  sl.registerFactory(() => EventsCubit(
    getEventsUseCase: sl<GetEventsUseCase>(),
    getEventDetailUseCase: sl<GetEventDetailUseCase>(),
  ));
  sl.registerFactory(() => TicketsCubit(
    getUserTicketsUseCase: sl<GetUserTicketsUseCase>(),
    createOrderUseCase: sl<CreateOrderUseCase>(),
    processPaymentUseCase: sl<ProcessPaymentUseCase>(),
  ));

  // Features - Explore
  // Data sources
  sl.registerLazySingleton<BusinessesRemoteDataSource>(
    () => BusinessesRemoteDataSourceImpl(),
  );

  // Repositories
  sl.registerLazySingleton<BusinessesRepository>(
    () => BusinessesRepositoryImpl(remoteDataSource: sl<BusinessesRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetBusinessesUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => GetBusinessDetailUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => GetDealsUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => GetDealDetailUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => GetBusinessReviewsUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => WriteReviewUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => RedeemDealUseCase(sl<BusinessesRepository>()));

  // Cubits
  sl.registerFactory(() => BusinessesCubit(
    getBusinessesUseCase: sl<GetBusinessesUseCase>(),
    getBusinessDetailUseCase: sl<GetBusinessDetailUseCase>(),
  ));
  sl.registerFactory(() => DealsCubit(
    getDealsUseCase: sl<GetDealsUseCase>(),
    getDealDetailUseCase: sl<GetDealDetailUseCase>(),
    redeemDealUseCase: sl<RedeemDealUseCase>(),
  ));
  sl.registerFactory(() => ReviewsCubit(
    getBusinessReviewsUseCase: sl<GetBusinessReviewsUseCase>(),
    writeReviewUseCase: sl<WriteReviewUseCase>(),
  ));

  // Features - Jobs
  // Data sources
  sl.registerLazySingleton<JobsRemoteDataSource>(
    () => JobsRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<JobsLocalDataSource>(
    () => JobsLocalDataSourceImpl(sl<LocalStorage>()),
  );
  sl.registerLazySingleton<JobApplicationsRemoteDataSource>(
    () => JobApplicationsRemoteDataSourceImpl(),
  );

  // Repositories
  sl.registerLazySingleton<JobsRepository>(
    () => JobsRepositoryImpl(
      remoteDataSource: sl<JobsRemoteDataSource>(),
      localDataSource: sl<JobsLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton<JobApplicationsRepository>(
    () => JobApplicationsRepositoryImpl(
      remoteDataSource: sl<JobApplicationsRemoteDataSource>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetJobsUseCase(sl<JobsRepository>()));
  sl.registerLazySingleton(() => GetJobDetailUseCase(sl<JobsRepository>()));
  sl.registerLazySingleton(() => ToggleBookmarkUseCase(sl<JobsRepository>()));
  sl.registerLazySingleton(() => GetJobCategoriesUseCase(sl<JobsRepository>()));
  sl.registerLazySingleton(() => SubmitApplicationUseCase(sl<JobApplicationsRepository>()));
  sl.registerLazySingleton(() => GetApplicationsUseCase(sl<JobApplicationsRepository>()));

  // Cubits
  sl.registerFactory(() => JobsCubit(
    getJobsUseCase: sl<GetJobsUseCase>(),
    getJobDetailUseCase: sl<GetJobDetailUseCase>(),
    toggleBookmarkUseCase: sl<ToggleBookmarkUseCase>(),
    getJobCategoriesUseCase: sl<GetJobCategoriesUseCase>(),
  ));
  sl.registerFactory(() => JobApplicationsCubit(
    submitApplicationUseCase: sl<SubmitApplicationUseCase>(),
    getApplicationsUseCase: sl<GetApplicationsUseCase>(),
  ));
}
