import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../../../choose_path/presentation/pages/choose_path_page.dart';
import '../../../home/presentation/pages/admin_home_page.dart';
import '../../../home/presentation/pages/business_owner_wrapper_page.dart';
import '../../../home/presentation/pages/customer_home_page.dart';
import '../widgets/social_auth_widgets.dart';
import 'business_email_sign_in_page.dart';
import 'business_sign_up_page.dart';
import 'email_verification_page.dart';
import 'wrong_path_page.dart';

/// Business owner entry: choose Email, Google, or Apple, then complete sign-in.
class BusinessSignInPage extends StatefulWidget {
  const BusinessSignInPage({super.key});

  @override
  State<BusinessSignInPage> createState() => _BusinessSignInPageState();
}

class _BusinessSignInPageState extends State<BusinessSignInPage> {
  void _handleNavigationForUser(BuildContext context, User user) {
    if (user.role == UserRole.customer || user.role == UserRole.guest) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const WrongPathPage(usedBusinessPath: true),
        ),
      );
      return;
    }

    final Widget destination;
    switch (user.role) {
      case UserRole.businessOwner:
        destination = BusinessOwnerWrapperPage(user: user);
        break;
      case UserRole.admin:
        destination = AdminHomePage(user: user);
        break;
      case UserRole.guest:
      case UserRole.customer:
        destination = CustomerHomePage(user: user);
        break;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _openEmailSignIn() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const BusinessEmailSignInPage(),
      ),
    );
  }

  void _openBusinessSignUp() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const BusinessSignUpPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ChoosePathPage()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ChoosePathPage()),
              );
            },
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              } else if (state is AuthEmailVerificationPending) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EmailVerificationPage(
                      email: state.email,
                      signUpRole: UserRole.businessOwner,
                      usePopWhenLeaving: true,
                    ),
                  ),
                );
              } else if (state is AuthAuthenticated) {
                _handleNavigationForUser(context, state.user);
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              final showApple =
                  !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
              final showGoogle = !kIsWeb &&
                  (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS);

              final bottomInset = MediaQuery.paddingOf(context).bottom;

              return Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppResources.spacingL,
                            vertical: AppResources.spacingM,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: AppFonts.largeTitle(
                                    color: AppColors.textPrimary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Business',
                                      style: AppFonts.largeTitle(
                                        color: AppColors.brandSecondary,
                                      ),
                                    ),
                                    const TextSpan(text: ' account sign in'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppResources.spacingM),
                              Text(
                                'Discover local businesses & connect with your people.',
                                style: AppFonts.body(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppResources.spacingXXL),
                              SizedBox(
                                height: AppResources.buttonHeightL,
                                child: ElevatedButton.icon(
                                        onPressed:
                                            isLoading ? null : _openEmailSignIn,
                                        icon: const Icon(
                                          Icons.mail_outline_rounded,
                                          color: AppColors.textOnPrimary,
                                          size: 22,
                                        ),
                                        label: Text(
                                          'Continue with Email',
                                          style: AppFonts.button(
                                            color: AppColors.textOnPrimary,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.brandPrimary,
                                          foregroundColor: AppColors.textOnPrimary,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppResources.radiusL,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                              if (showGoogle || showApple) ...[
                                const SizedBox(height: AppResources.spacingL),
                                const AuthOrDivider(),
                                const SizedBox(height: AppResources.spacingL),
                              ],
                              if (showGoogle) ...[
                                GoogleSignInButton(
                                  height: AppResources.buttonHeightL,
                                  borderRadius: AppResources.radiusL,
                                  onPressed: isLoading
                                      ? null
                                      : () => context
                                          .read<AuthCubit>()
                                          .signInWithGoogle(),
                                ),
                                if (showApple)
                                  const SizedBox(height: AppResources.spacingM),
                              ],
                              if (showApple)
                                SizedBox(
                                  height: AppResources.buttonHeightL,
                                  width: double.infinity,
                                  child: SignInWithAppleButton(
                                    onPressed: () {
                                      if (isLoading) return;
                                      context.read<AuthCubit>().signInWithApple();
                                    },
                                    text: 'Continue with Apple',
                                    style: SignInWithAppleButtonStyle.black,
                                    height: AppResources.buttonHeightL,
                                  ),
                                ),
                              const SizedBox(height: AppResources.spacingXL),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppResources.spacingL,
                          AppResources.spacingM,
                          AppResources.spacingL,
                          bottomInset + AppResources.spacingM,
                        ),
                        child: Center(
                          child: TextButton(
                            onPressed: isLoading ? null : _openBusinessSignUp,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                            ),
                            child: Text.rich(
                              TextSpan(
                                style: AppFonts.body(
                                  color: AppColors.textSecondary,
                                ),
                                children: [
                                  const TextSpan(text: 'New to Habra? '),
                                  TextSpan(
                                    text: 'Sign up',
                                    style: AppFonts.body(
                                      color: AppColors.brandSecondary,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isLoading)
                    ColoredBox(
                      color: Colors.black.withValues(alpha: 0.25),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
