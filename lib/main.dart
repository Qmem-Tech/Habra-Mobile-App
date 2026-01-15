import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:habra_mobile_app/l10n/app_localizations.dart';

import 'injection/injection_container.dart' as di;
import 'core/network/firebase/firebase_config.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/theme_state.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/localization_cubit.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/login_as_guest_usecase.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/splash/presentation/bloc/splash_cubit.dart';
import 'features/splash/domain/usecases/get_splash_status_usecase.dart';
import 'features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'features/onboarding/domain/usecases/complete_onboarding_usecase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseConfig.initialize();

  // Initialize Dependency Injection
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<ThemeCubit>(),
        ),
        BlocProvider(
          create: (_) => di.sl<LocalizationCubit>(),
        ),
        BlocProvider(
          create: (_) => AuthCubit(
            loginUseCase: di.sl<LoginUseCase>(),
            logoutUseCase: di.sl<LogoutUseCase>(),
            registerUseCase: di.sl<RegisterUseCase>(),
            loginAsGuestUseCase: di.sl<LoginAsGuestUseCase>(),
          ),
        ),
        BlocProvider(
          create: (_) => SplashCubit(
            getSplashStatusUseCase: di.sl<GetSplashStatusUseCase>(),
          ),
        ),
        BlocProvider(
          create: (_) => OnboardingCubit(
            completeOnboardingUseCase: di.sl<CompleteOnboardingUseCase>(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          return BlocBuilder<LocalizationCubit, LocalizationState>(
            builder: (context, localeState) {
              return BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, themeState) {
                  return MaterialApp(
                    title: 'Habra Mobile App',
                    debugShowCheckedModeBanner: false,

                    // Theme
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: context.read<ThemeCubit>().themeMode,

                    // Localization
                    locale: localeState.locale,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: context.read<LocalizationCubit>().supportedLocales,

                    // Home - Start with splash screen
                    home: const SplashPage(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
