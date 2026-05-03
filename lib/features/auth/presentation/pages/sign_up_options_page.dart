import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../../domain/entities/user.dart';
import '../../../home/presentation/pages/customer_home_page.dart';
import '../../../home/presentation/pages/business_owner_wrapper_page.dart';
import '../../../home/presentation/pages/admin_home_page.dart';
import '../../../home/presentation/pages/guest_home_page.dart';
import 'email_sign_up_page.dart';
import 'sign_in_page.dart';
import '../../../choose_path/presentation/pages/choose_path_page.dart';
import '../widgets/social_auth_widgets.dart';

bool _isUserCancelledOAuthMessage(String message) {
  final m = message.toLowerCase().trim();
  if (m.isEmpty) return false;
  if (m.contains('12501')) return true;
  if (m.contains('sign_in_canceled') || m.contains('sign_in_cancelled')) {
    return true;
  }
  if (m.contains('user canceled') || m.contains('user cancelled')) return true;
  if (m.contains('canceled') || m.contains('cancelled')) return true;
  if (m.contains('cancel')) return true;
  if (m.contains('user denied')) return true;
  if (m.contains('authorizationerrorcode.canceled')) return true;
  return false;
}

class SignUpOptionsPage extends StatelessWidget {
  const SignUpOptionsPage({super.key, this.selectedRole});

  /// Role chosen on ChoosePathPage (business owner vs community member).
  /// When null (e.g. opened from sign-in "Sign up" link), defaults to customer.
  final UserRole? selectedRole;

  void _handleNavigationForUser(BuildContext context, User user) {
    Widget destination;
    switch (user.role) {
      case UserRole.businessOwner:
        destination = BusinessOwnerWrapperPage(user: user);
        break;
      case UserRole.admin:
        destination = AdminHomePage(user: user);
        break;
      case UserRole.guest:
        destination = GuestHomePage(user: user);
        break;
      case UserRole.customer:
        destination = CustomerHomePage(user: user);
        break;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _onAuthListen(BuildContext context, AuthState state) {
    if (state is AuthError) {
      if (_isUserCancelledOAuthMessage(state.message)) {
        context.read<AuthCubit>().resetToInitial();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
      context.read<AuthCubit>().resetToInitial();
    } else if (state is AuthAuthenticated) {
      _handleNavigationForUser(context, state.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) =>
          curr is AuthError || curr is AuthAuthenticated,
      listener: _onAuthListen,
      builder: (context, state) {
        final showApple =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
        final showGoogle = !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS);
        final isLoading = state is AuthLoading;
        final hasSocial = showGoogle || showApple;

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
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ChoosePathPage()),
                  );
                },
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppResources.spacingL,
                  vertical: AppResources.spacingS,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppResources.spacingM),
                    RichText(
                      text: TextSpan(
                        style: AppFonts.largeTitle(color: AppColors.textPrimary)
                            .copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                        children: [
                          TextSpan(
                            text: 'User',
                            style: AppFonts.largeTitle(
                              color: AppColors.brandSecondary,
                            ).copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.15,
                            ),
                          ),
                          const TextSpan(text: ' account sign up'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppResources.spacingM),
                    Text(
                      'Discover local businesses & connect with your people.',
                      style: AppFonts.body(color: AppColors.textSecondary)
                          .copyWith(height: 1.4, fontSize: 16),
                    ),
                    const SizedBox(height: AppResources.spacingXXL),

                    _PrimarySignUpButton(
                      icon: Icons.mail_outline_rounded,
                      label: 'Continue with Email',
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => EmailSignUpPage(
                                    selectedRole:
                                        selectedRole ?? UserRole.customer,
                                  ),
                                ),
                              );
                            },
                    ),

                    if (hasSocial) ...[
                      const SizedBox(height: AppResources.spacingL),
                      const AuthOrDivider(),
                      const SizedBox(height: AppResources.spacingL),
                    ],

                    if (showGoogle) ...[
                      GoogleSignInButton(
                        height: AppResources.buttonHeightL,
                        borderRadius: AppResources.radiusL,
                        foregroundColor: AppColors.textSecondary,
                        borderColor:
                            AppColors.backgroundGrey.withValues(alpha: 0.9),
                        onPressed: isLoading
                            ? null
                            : () => context
                                .read<AuthCubit>()
                                .signInWithGoogle(),
                      ),
                      if (showApple) const SizedBox(height: AppResources.spacingM),
                    ],

                    if (showApple)
                      AppleSignInButton(
                        height: AppResources.buttonHeightL,
                        borderRadius: AppResources.radiusL,
                        onPressed: isLoading
                            ? null
                            : () => context.read<AuthCubit>().signInWithApple(),
                      ),

                    SizedBox(
                      height: AppResources.spacingXXL +
                          MediaQuery.paddingOf(context).bottom,
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppFonts.body(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const SignInPage(),
                                    ),
                                  );
                                },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppColors.brandSecondary,
                          ),
                          child: Text(
                            'Log in',
                            style: AppFonts.body(color: AppColors.brandSecondary)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppResources.spacingL),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PrimarySignUpButton extends StatelessWidget {
  const _PrimarySignUpButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppResources.buttonHeightL,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.customerHomePrimary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor:
              AppColors.customerHomePrimary.withValues(alpha: 0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppResources.radiusL),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: AppColors.textOnPrimary),
            const SizedBox(width: AppResources.spacingM),
            Text(
              label,
              style: AppFonts.button(color: AppColors.textOnPrimary).copyWith(
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
