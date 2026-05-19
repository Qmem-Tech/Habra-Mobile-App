import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../features/events/presentation/bloc/create_event_cubit.dart';
import '../../features/home/presentation/bloc/business_owner_home_cubit.dart';
import '../../features/home/presentation/bloc/business_owner_subscription_cubit.dart';

/// Providers for owner create/edit routes (deals, jobs, events).
///
/// Pass the **caller** [parentContext] (from [Navigator.push], not the route
/// [builder] context). Includes [BusinessOwnerSubscriptionCubit] so limits
/// use the active RevenueCat plan instead of defaulting to Basic.
List<BlocProvider> businessOwnerToolRouteProviders(
  BuildContext parentContext, {
  DashboardCubit? dashboard,
  BusinessOwnerHomeCubit? home,
  CreateEventCubit? createEvent,
}) {
  return [
    if (dashboard != null)
      BlocProvider<DashboardCubit>.value(value: dashboard),
    if (home != null)
      BlocProvider<BusinessOwnerHomeCubit>.value(value: home),
    BlocProvider<BusinessOwnerSubscriptionCubit>.value(
      value: parentContext.read<BusinessOwnerSubscriptionCubit>(),
    ),
    if (createEvent != null)
      BlocProvider<CreateEventCubit>.value(value: createEvent),
  ];
}
