# Home Feature Implementation Summary

This document outlines the implementation of the Home page and related features for the Habra Mobile App following Clean Architecture principles.

## 📁 Structure

The implementation follows Clean Architecture with three layers:

### Domain Layer
- **Entities**: `Event`, `Deal`, `Business`, `Job`, `NotificationEntity`, `LocationEntity`
- **Repositories**: `HomeRepository`, `SearchRepository`, `NotificationRepository`
- **Use Cases**:
  - `GetHappeningThisWeekUseCase`
  - `GetHotDealsUseCase`
  - `GetPopularBusinessesUseCase`
  - `GetLatestJobsUseCase`
  - `SearchUseCase`
  - `GetNotificationsUseCase`

### Data Layer
- **Models**: `EventModel`, `DealModel`, `BusinessModel`, `JobModel`, `NotificationModel`
- **Data Sources**:
  - `HomeRemoteDataSource`
  - `SearchRemoteDataSource` & `SearchLocalDataSource`
  - `NotificationRemoteDataSource`
- **Repositories**: `HomeRepositoryImpl`, `SearchRepositoryImpl`, `NotificationRepositoryImpl`

### Presentation Layer
- **Cubits/States**:
  - `HomeCubit` / `HomeState`
  - `SearchCubit` / `SearchState`
  - `NotificationCubit` / `NotificationState`
- **Pages**:
  - `HomePage` (main home screen)
  - `SearchPage` (search interface)
  - `SearchResultsPage` (search results display)
  - `NotificationPage` (notifications list)
  - `LocationSelectionPage` (location picker)
  - `NavigationDrawer` (side menu)
- **Widgets**:
  - `EventCard`
  - `DealCard`
  - `BusinessCard`
  - `JobCard`

## 🎨 Assets Required

Please add the following assets to your project:

### Images
Place these in `assets/images/home/`:

- `event_placeholder.png` - Placeholder for event images
- `deal_placeholder.png` - Placeholder for deal images
- `business_placeholder.png` - Placeholder for business images
- `job_placeholder.png` - Placeholder for job images
- `notification_empty.png` - Empty state illustration for notifications
- `no_results.png` - Empty state illustration for no search results

**Note**: The current implementation uses network images with error builders that display icons as fallbacks. You can update the `AppAssets` class references once you add these assets.

## 🔌 TODO: Backend Integration

The following remote data sources need backend implementation:

1. **HomeRemoteDataSource**:
   - `getHappeningThisWeek()` - Fetch events happening this week
   - `getHotDealsNearYou()` - Fetch hot deals based on location
   - `getPopularBusinesses()` - Fetch popular businesses
   - `getLatestJobs()` - Fetch latest job postings

2. **SearchRemoteDataSource**:
   - `search()` - Search for events, businesses, and jobs
   - `getTrendingSearches()` - Get trending search terms

3. **NotificationRemoteDataSource**:
   - `getNotifications()` - Fetch user notifications
   - `markAsRead()` - Mark notification as read
   - `markAllAsRead()` - Mark all notifications as read
   - `getUnreadCount()` - Get unread notification count

## 🧩 Dependency Injection

You'll need to register the following dependencies in `injection_container.dart`:

```dart
// Data Sources
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

// Use Cases
sl.registerLazySingleton(() => GetHappeningThisWeekUseCase(sl<HomeRepository>()));
sl.registerLazySingleton(() => GetHotDealsUseCase(sl<HomeRepository>()));
sl.registerLazySingleton(() => GetPopularBusinessesUseCase(sl<HomeRepository>()));
sl.registerLazySingleton(() => GetLatestJobsUseCase(sl<HomeRepository>()));
sl.registerLazySingleton(() => SearchUseCase(sl<SearchRepository>()));
sl.registerLazySingleton(() => GetNotificationsUseCase(sl<NotificationRepository>()));

// Cubits
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
```

## 📱 Features Implemented

### Home Page
- ✅ Header with menu, location selector, and notifications icon
- ✅ Personalized greeting
- ✅ Search bar
- ✅ "Happening This Week" section with horizontal scrollable event cards
- ✅ "Hot Deals Near You" section with horizontal scrollable deal cards
- ✅ "Popular Businesses" section with vertical list
- ✅ "Latest Jobs" section with vertical list
- ✅ Empty state for no results
- ✅ Bottom navigation bar

### Search Page
- ✅ Search input with cancel button
- ✅ Category filters (All, Events, Business, Jobs)
- ✅ Recent searches with clear all option
- ✅ Trending searches chips
- ✅ Real-time search results

### Search Results Page
- ✅ Results summary with count
- ✅ Sort dropdown
- ✅ Grid layout for businesses (2 columns)
- ✅ List layout for events and jobs
- ✅ Empty state handling

### Notifications Page
- ✅ Grouped notifications (Today, Yesterday, This Week)
- ✅ Different notification types (message, deal, event, job)
- ✅ Timestamp formatting
- ✅ Empty state illustration
- ✅ Mark as read functionality

### Location Selection Page
- ✅ Search bar for locations
- ✅ Use current location option
- ✅ List of available locations
- ✅ Selected location indication

### Navigation Drawer
- ✅ User profile section
- ✅ Menu items (Home, Events, Community Groups, Messages, etc.)
- ✅ Sign out option
- ✅ Active state indication

## 🎯 Next Steps

1. **Add Assets**: Place the required image assets in the specified paths
2. **Backend Integration**: Implement the remote data sources with Firebase/API calls
3. **Dependency Injection**: Register all dependencies in `injection_container.dart`
4. **Location Service**: Implement location detection and storage
5. **Navigation**: Complete navigation to other pages (Events, Messages, etc.)
6. **Testing**: Add unit tests for use cases and widget tests for UI components

## 📝 Notes

- The current implementation uses placeholder/mock data structures. Replace with actual backend calls.
- Location management needs to be integrated with a location service (geolocator package recommended).
- Image loading uses `Image.network` with error builders. Consider using a caching solution (cached_network_image) for production.
- The navigation drawer sign out uses `AuthCubit` - ensure it's available in the widget tree.
