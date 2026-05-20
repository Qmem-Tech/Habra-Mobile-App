import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/network/network_info.dart';
import '../core/storage/local_storage.dart';
import '../core/localization/localization_cubit.dart';
import '../core/services/location_service.dart';
import '../core/services/image_picker_service.dart';
import '../core/services/permission_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/app_version_service.dart';
import '../core/services/push_notification_service.dart';
import '../core/services/revenue_cat_service.dart';
import '../core/subscription/subscription_trial_service.dart';
import '../core/services/stripe_payment_service.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/datasources/auth_local_datasource.dart';
import '../features/auth/data/datasources/auth_supabase_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/register_usecase.dart';
import '../features/auth/domain/usecases/login_as_guest_usecase.dart';
import '../features/auth/domain/usecases/sign_in_with_apple_usecase.dart';
import '../features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import '../features/auth/domain/usecases/resend_verification_email_usecase.dart';
import '../features/auth/domain/usecases/reset_password_for_email_usecase.dart';
import '../features/auth/domain/usecases/update_password_usecase.dart';

// Splash feature
import '../features/splash/data/repositories/splash_repository_supabase_impl.dart';
import '../features/splash/domain/repositories/splash_repository.dart';
import '../features/splash/domain/usecases/get_splash_status_usecase.dart';

// Onboarding feature
import '../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../features/onboarding/domain/usecases/complete_onboarding_usecase.dart';

// Home feature
import '../features/home/data/datasources/home_remote_datasource.dart';
import '../features/home/data/datasources/home_supabase_datasource.dart';
import '../features/home/data/datasources/search_remote_datasource.dart';
import '../features/home/data/datasources/search_local_datasource.dart';
import '../features/home/data/datasources/notification_remote_datasource.dart';
import '../features/home/data/datasources/notification_supabase_datasource.dart';
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
import '../features/home/presentation/bloc/business_owner_home_cubit.dart';
import '../features/home/presentation/bloc/business_owner_subscription_cubit.dart';
import '../features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../features/dashboard/data/datasources/dashboard_supabase_datasource.dart';
import '../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../features/dashboard/presentation/bloc/dashboard_cubit.dart';
// Events feature
import '../features/events/data/datasources/events_remote_datasource.dart';
import '../features/events/data/datasources/events_supabase_datasource.dart';
import '../features/events/data/datasources/ticket_resale_datasource.dart';
import '../features/events/data/repositories/events_repository_impl.dart';
import '../features/events/domain/repositories/events_repository.dart';
import '../features/events/domain/usecases/get_events_by_business_usecase.dart';
import '../features/events/domain/usecases/get_events_usecase.dart';
import '../features/events/domain/usecases/get_event_detail_usecase.dart';
import '../features/events/domain/usecases/get_user_tickets_usecase.dart';
import '../features/events/domain/usecases/create_order_usecase.dart';
import '../features/events/domain/usecases/process_payment_usecase.dart';
import '../features/events/domain/usecases/cancel_unpaid_event_order_usecase.dart';
import '../features/events/domain/usecases/create_event_usecase.dart';
import '../features/events/domain/usecases/update_event_usecase.dart';
import '../features/events/presentation/bloc/events_cubit.dart';
import '../features/events/presentation/bloc/tickets_cubit.dart';
import '../features/events/presentation/bloc/create_event_cubit.dart';

// Explore feature
import '../features/explore/data/datasources/businesses_remote_datasource.dart';
import '../features/explore/data/datasources/businesses_supabase_datasource.dart';
import '../features/explore/data/datasources/categories_remote_datasource.dart';
import '../features/explore/data/datasources/categories_supabase_datasource.dart';
import '../features/explore/data/repositories/businesses_repository_impl.dart';
import '../features/explore/data/repositories/categories_repository_impl.dart';
import '../features/explore/domain/repositories/businesses_repository.dart';
import '../features/explore/domain/repositories/categories_repository.dart';
import '../features/explore/domain/usecases/get_businesses_usecase.dart';
import '../features/explore/domain/usecases/get_business_detail_usecase.dart';
import '../features/explore/domain/usecases/get_deals_usecase.dart';
import '../features/explore/domain/usecases/get_deal_detail_usecase.dart';
import '../features/explore/domain/usecases/get_business_reviews_usecase.dart';
import '../features/explore/domain/usecases/write_review_usecase.dart';
import '../features/explore/domain/usecases/redeem_deal_usecase.dart';
import '../features/explore/domain/usecases/get_my_reviews_usecase.dart';
import '../features/explore/domain/usecases/update_my_review_usecase.dart';
import '../features/explore/domain/usecases/delete_my_review_usecase.dart';
import '../features/explore/domain/usecases/get_active_listing_categories_usecase.dart';
import '../features/explore/presentation/bloc/businesses_cubit.dart';
import '../features/explore/presentation/bloc/deals_cubit.dart';
import '../features/explore/presentation/bloc/reviews_cubit.dart';
import '../features/explore/presentation/bloc/my_reviews_cubit.dart';

// Jobs feature
import '../features/jobs/data/datasources/jobs_remote_datasource.dart';
import '../features/jobs/data/datasources/jobs_supabase_datasource.dart';
import '../features/jobs/data/datasources/jobs_local_datasource.dart';
import '../features/jobs/data/datasources/job_applications_remote_datasource.dart';
import '../features/jobs/data/datasources/job_applications_supabase_datasource.dart';
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
import '../features/jobs/domain/usecases/upload_resume_usecase.dart';
import '../features/jobs/presentation/bloc/jobs_cubit.dart';
import '../features/jobs/presentation/bloc/job_applications_cubit.dart';

// Feedback feature
import '../features/feedback/data/datasources/feedback_remote_datasource.dart';
import '../features/feedback/data/datasources/feedback_supabase_datasource.dart';
import '../features/feedback/data/repositories/feedback_repository_impl.dart';
import '../features/feedback/domain/repositories/feedback_repository.dart';
import '../features/feedback/domain/usecases/submit_feedback_usecase.dart';
import '../features/feedback/domain/usecases/list_feedback_for_admin_usecase.dart';
import '../features/feedback/domain/usecases/update_admin_feedback_usecase.dart';
import '../features/feedback/presentation/bloc/feedback_cubit.dart';
import '../features/feedback/presentation/bloc/admin_feedback_cubit.dart';
import '../features/profile/data/datasources/profile_remote_datasource.dart';
import '../features/profile/data/datasources/profile_supabase_datasource.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/domain/usecases/get_profile_usecase.dart';
import '../features/profile/domain/usecases/update_profile_usecase.dart';
import '../features/profile/domain/usecases/upload_avatar_usecase.dart';
import '../features/profile/presentation/bloc/edit_profile_cubit.dart';
import '../features/saved_items/data/datasources/saved_items_remote_datasource.dart';
import '../features/saved_items/data/datasources/saved_items_supabase_datasource.dart';
import '../features/saved_items/data/repositories/saved_items_repository_impl.dart';
import '../features/saved_items/domain/repositories/saved_items_repository.dart';
import '../features/saved_items/domain/usecases/get_saved_items_usecase.dart';
import '../features/saved_items/domain/usecases/remove_saved_item_usecase.dart';
import '../features/saved_items/domain/usecases/save_item_usecase.dart';
import '../features/saved_items/presentation/bloc/saved_items_cubit.dart';

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

  // Localization
  sl.registerFactory(() => LocalizationCubit(localStorage: sl<LocalStorage>()));

  // Services
  sl.registerLazySingleton<LocationService>(() => LocationService(dio: sl<Dio>()));
  sl.registerLazySingleton<ImagePickerService>(() => ImagePickerService());
  sl.registerLazySingleton<PermissionService>(() => PermissionService());
  sl.registerLazySingleton<StorageService>(() => StorageService());
  sl.registerLazySingleton<RevenueCatService>(() => RevenueCatService());
  sl.registerLazySingleton<SubscriptionTrialService>(() => SubscriptionTrialService());
  sl.registerLazySingleton<StripePaymentService>(() => StripePaymentService());
  sl.registerLazySingleton<AppVersionService>(() => AppVersionService());
  sl.registerLazySingleton<PushNotificationService>(
    () => PushNotificationService(sl<LocalStorage>()),
  );

  // Features - Auth (Supabase only)
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthSupabaseRemoteDataSource(),
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
  sl.registerLazySingleton(() => SignInWithAppleUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ResendVerificationEmailUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ResetPasswordForEmailUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => UpdatePasswordUseCase(sl<AuthRepository>()));

  // Features - Splash (Supabase only)
  sl.registerLazySingleton<SplashRepository>(
    () => SplashRepositorySupabaseImpl(
      localStorage: sl<LocalStorage>(),
      authLocalDataSource: sl<AuthLocalDataSource>(),
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
    () => HomeSupabaseDataSource(),
  );
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<SearchLocalDataSource>(
    () => SearchLocalDataSourceImpl(sl<LocalStorage>()),
  );
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationSupabaseDataSource(),
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
  // Features - Dashboard (Business Owner) — Supabase
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardSupabaseDataSource(),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(remoteDataSource: sl<DashboardRemoteDataSource>()),
  );
  sl.registerFactory(() => DashboardCubit(sl<DashboardRepository>()));
  sl.registerFactory(() => BusinessOwnerHomeCubit(
      sl<DashboardRepository>(),
      sl<LocalStorage>(),
    ));
  sl.registerFactory(() => BusinessOwnerSubscriptionCubit(
        sl<RevenueCatService>(),
        sl<SubscriptionTrialService>(),
      ));

  // Features - Events
  // Data sources
  sl.registerLazySingleton<EventsRemoteDataSource>(
    () => EventsSupabaseDataSource(),
  );
  sl.registerLazySingleton<TicketResaleDatasource>(() => TicketResaleDatasource());

  // Repositories
  sl.registerLazySingleton<EventsRepository>(
    () => EventsRepositoryImpl(sl<EventsRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetEventsUseCase(sl<EventsRepository>()));
  sl.registerLazySingleton(
    () => GetEventsByBusinessUseCase(sl<EventsRepository>()),
  );
  sl.registerLazySingleton(() => GetEventDetailUseCase(sl<EventsRepository>()));
  sl.registerLazySingleton(() => GetUserTicketsUseCase(sl<EventsRepository>()));
  sl.registerLazySingleton(() => CreateOrderUseCase(sl<EventsRepository>()));
  sl.registerLazySingleton(() => ProcessPaymentUseCase(sl<EventsRepository>()));
  sl.registerLazySingleton(
    () => CancelUnpaidEventOrderUseCase(sl<EventsRepository>()),
  );
  sl.registerLazySingleton(() => CreateEventUseCase(sl<EventsRepository>()));
  sl.registerLazySingleton(() => UpdateEventUseCase(sl<EventsRepository>()));

  // Cubits
  sl.registerFactory(
    () => CreateEventCubit(
      sl<CreateEventUseCase>(),
      sl<UpdateEventUseCase>(),
    ),
  );
  sl.registerFactory(() => EventsCubit(
    getEventsUseCase: sl<GetEventsUseCase>(),
    getEventDetailUseCase: sl<GetEventDetailUseCase>(),
  ));
  sl.registerFactory(() => TicketsCubit(
    getUserTicketsUseCase: sl<GetUserTicketsUseCase>(),
    createOrderUseCase: sl<CreateOrderUseCase>(),
    processPaymentUseCase: sl<ProcessPaymentUseCase>(),
    cancelUnpaidEventOrderUseCase: sl<CancelUnpaidEventOrderUseCase>(),
    stripePaymentService: sl<StripePaymentService>(),
  ));

  // Features - Explore
  // Data sources
  sl.registerLazySingleton<BusinessesRemoteDataSource>(
    () => BusinessesSupabaseDataSource(),
  );
  sl.registerLazySingleton<CategoriesRemoteDataSource>(
    () => CategoriesSupabaseDataSource(),
  );

  // Repositories
  sl.registerLazySingleton<BusinessesRepository>(
    () => BusinessesRepositoryImpl(remoteDataSource: sl<BusinessesRemoteDataSource>()),
  );
  sl.registerLazySingleton<CategoriesRepository>(
    () => CategoriesRepositoryImpl(remoteDataSource: sl<CategoriesRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetActiveListingCategoriesUseCase(sl<CategoriesRepository>()));
  sl.registerLazySingleton(() => GetBusinessesUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => GetBusinessDetailUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => GetDealsUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => GetDealDetailUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => GetBusinessReviewsUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => WriteReviewUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => RedeemDealUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => GetMyReviewsUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => UpdateMyReviewUseCase(sl<BusinessesRepository>()));
  sl.registerLazySingleton(() => DeleteMyReviewUseCase(sl<BusinessesRepository>()));

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
  sl.registerFactory(() => MyReviewsCubit(
    getMyReviewsUseCase: sl<GetMyReviewsUseCase>(),
    updateMyReviewUseCase: sl<UpdateMyReviewUseCase>(),
    deleteMyReviewUseCase: sl<DeleteMyReviewUseCase>(),
  ));

  // Features - Jobs
  // Data sources
  sl.registerLazySingleton<JobsRemoteDataSource>(
    () => JobsSupabaseDataSource(),
  );
  sl.registerLazySingleton<JobsLocalDataSource>(
    () => JobsLocalDataSourceImpl(sl<LocalStorage>()),
  );
  sl.registerLazySingleton<JobApplicationsRemoteDataSource>(
    () => JobApplicationsSupabaseDataSource(),
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
  sl.registerLazySingleton(() => UploadResumeUseCase(sl<JobApplicationsRepository>()));

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
    uploadResumeUseCase: sl<UploadResumeUseCase>(),
  ));

  // Features - Feedback
  sl.registerLazySingleton<FeedbackRemoteDataSource>(
    () => FeedbackSupabaseDataSource(),
  );
  sl.registerLazySingleton<FeedbackRepository>(
    () => FeedbackRepositoryImpl(remoteDataSource: sl<FeedbackRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => SubmitFeedbackUseCase(sl<FeedbackRepository>()));
  sl.registerLazySingleton(
    () => ListFeedbackForAdminUseCase(sl<FeedbackRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateAdminFeedbackUseCase(sl<FeedbackRepository>()),
  );
  sl.registerFactory(() => FeedbackCubit(submitFeedbackUseCase: sl<SubmitFeedbackUseCase>()));
  sl.registerFactory(
    () => AdminFeedbackCubit(
      listUseCase: sl<ListFeedbackForAdminUseCase>(),
      updateUseCase: sl<UpdateAdminFeedbackUseCase>(),
    ),
  );

  // Features - Profile
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileSupabaseDataSource(),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl<ProfileRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => GetProfileUseCase(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UploadAvatarUseCase(sl<ProfileRepository>()));
  sl.registerFactory(() => EditProfileCubit(
    getProfileUseCase: sl<GetProfileUseCase>(),
    updateProfileUseCase: sl<UpdateProfileUseCase>(),
    uploadAvatarUseCase: sl<UploadAvatarUseCase>(),
  ));

  // Features - Saved Items
  sl.registerLazySingleton<SavedItemsRemoteDataSource>(
    () => SavedItemsSupabaseDataSource(),
  );
  sl.registerLazySingleton<SavedItemsRepository>(
    () => SavedItemsRepositoryImpl(remoteDataSource: sl<SavedItemsRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => GetSavedItemsUseCase(sl<SavedItemsRepository>()));
  sl.registerLazySingleton(() => SaveItemUseCase(sl<SavedItemsRepository>()));
  sl.registerLazySingleton(() => RemoveSavedItemUseCase(sl<SavedItemsRepository>()));
  sl.registerFactory(() => SavedItemsCubit(
        getSavedItemsUseCase: sl<GetSavedItemsUseCase>(),
        removeSavedItemUseCase: sl<RemoveSavedItemUseCase>(),
      ));
}
