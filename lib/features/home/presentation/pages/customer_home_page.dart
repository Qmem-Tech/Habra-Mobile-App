import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/location/session_device_location_cubit.dart';
import '../../../../core/services/location_service.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../../core/navigation/main_navigation_wrapper.dart';
import '../bloc/home_cubit.dart';
import '../bloc/search_cubit.dart';
import '../bloc/notification_cubit.dart';
import 'home_page.dart';

class CustomerHomePage extends StatelessWidget {
  final User user;

  const CustomerHomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<HomeCubit>()),
        BlocProvider(create: (_) => di.sl<SearchCubit>()),
        BlocProvider(create: (_) => di.sl<NotificationCubit>()),
        BlocProvider(
          create: (_) {
            final c = SessionDeviceLocationCubit(di.sl<LocationService>());
            c.refreshFromDeviceGps();
            return c;
          },
        ),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (prev, curr) {
          if (curr is! AuthAuthenticated) return false;
          final prevUser = prev is AuthAuthenticated ? prev.user : null;
          return prevUser != curr.user;
        },
        builder: (context, authState) {
          final effective =
              authState is AuthAuthenticated ? authState.user : user;
          return MainNavigationWrapper(
            initialIndex: 0,
            userId: effective.id,
            userName: effective.name,
            userEmail: effective.email,
            user: effective,
            userAvatarUrl: effective.avatarUrl,
            homePage: HomePage(
              userId: effective.id,
              userName: effective.name,
              useSessionDeviceLocation: true,
            ),
          );
        },
      ),
    );
  }
}
