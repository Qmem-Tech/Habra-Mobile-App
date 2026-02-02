import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../../core/navigation/business_owner_navigation_wrapper.dart';
import '../../../auth/domain/entities/user.dart';
import '../bloc/business_owner_home_cubit.dart';
import '../bloc/notification_cubit.dart';

/// Wraps business owner flow with cubits and bottom nav (Home, Dash, Boosts, Messages, Profile).
class BusinessOwnerWrapperPage extends StatelessWidget {
  final User user;

  const BusinessOwnerWrapperPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<BusinessOwnerHomeCubit>(),
        ),
        BlocProvider(
          create: (_) => di.sl<NotificationCubit>(),
        ),
      ],
      child: BusinessOwnerNavigationWrapper(
        user: user,
        initialIndex: 0,
      ),
    );
  }
}
