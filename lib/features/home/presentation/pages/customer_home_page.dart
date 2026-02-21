import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/user.dart';
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
      ],
      child: MainNavigationWrapper(
        initialIndex: 0,
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
        user: user,
        homePage: HomePage(
          userId: user.id,
          userName: user.name,
          currentLocation: null, // TODO: Get from location service or storage
        ),
      ),
    );
  }
}
