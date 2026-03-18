import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:habra_mobile_app/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:habra_mobile_app/l10n/app_localizations.dart';
import 'core/services/revenue_cat_service.dart';
import 'injection/injection_container.dart' as di;
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/localization/localization_cubit.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/login_as_guest_usecase.dart';
import 'features/auth/domain/usecases/resend_verification_email_usecase.dart';
import 'features/auth/domain/usecases/reset_password_for_email_usecase.dart';
import 'features/auth/domain/usecases/update_password_usecase.dart';
import 'features/auth/presentation/widgets/auth_deep_link_handler.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/splash/presentation/bloc/splash_cubit.dart';
import 'features/splash/domain/usecases/get_splash_status_usecase.dart';
import 'features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'features/onboarding/domain/usecases/complete_onboarding_usecase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase is the only backend; require it at startup.
  SupabaseConfig.assertConfigured();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize Dependency Injection
  await di.init();
await di.sl<RevenueCatService>().initialize(
  androidApiKey: 'goog_nHVKdWnjfioxqUPHHWyqNCHGyje', // sandbox
  iosApiKey: 'appl_QiOyMwzXQMBXebSnUfYYwXxJtgg',
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<LocalizationCubit>(),
        ),
        BlocProvider(
          create: (_) => AuthCubit(
            loginUseCase: di.sl<LoginUseCase>(),
            logoutUseCase: di.sl<LogoutUseCase>(),
            registerUseCase: di.sl<RegisterUseCase>(),
            loginAsGuestUseCase: di.sl<LoginAsGuestUseCase>(),
            signInWithGoogleUseCase: di.sl<SignInWithGoogleUseCase>(),
            resendVerificationEmailUseCase: di.sl<ResendVerificationEmailUseCase>(),
            resetPasswordForEmailUseCase: di.sl<ResetPasswordForEmailUseCase>(),
            updatePasswordUseCase: di.sl<UpdatePasswordUseCase>(),
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
              return MaterialApp(
                title: 'Habra',
                debugShowCheckedModeBanner: false,

                // Theme – single light theme only
                theme: AppTheme.theme,

                // Localization
                locale: localeState.locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: context.read<LocalizationCubit>().supportedLocales,

                // Home - AuthDeepLinkHandler listens for password recovery links
                home: const AuthDeepLinkHandler(child: SplashPage()),
              );
            },
          );
        },
      ),
    );
  }
}
