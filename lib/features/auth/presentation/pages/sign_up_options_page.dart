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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is AuthAuthenticated) {
          _handleNavigationForUser(context, state.user);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
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
            vertical: AppResources.spacingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppResources.spacingXL),

              // Title with highlighted "User"
              RichText(
                text: TextSpan(
                  style: AppFonts.largeTitle(color: AppColors.textPrimary),
                  children: [
                    TextSpan(
                      text: 'User ',
                      style: AppFonts.largeTitle(color: AppColors.brandSecondary),
                    ),
                    const TextSpan(text: 'account sign up'),
                  ],
                ),
              ),
              const SizedBox(height: AppResources.spacingM),

              // Subtitle
              Text(
                'Discover local businesses & connect with your people.',
                style: AppFonts.body(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppResources.spacingXXL),

              // Continue with Email button
              _buildSignUpButton(
                icon: Icons.email,
                label: 'Continue with Email',
                backgroundColor: AppColors.brandPrimary,
                textColor: AppColors.textOnPrimary,
                iconColor: AppColors.textOnPrimary,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EmailSignUpPage(
                        selectedRole: selectedRole ?? UserRole.customer,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppResources.spacingM),


              // OR separator
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha:0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                    child: Text(
                      'or',
                      style: AppFonts.bodySmall(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha:0.3))),
                ],
              ),
              const SizedBox(height: AppResources.spacingM),

              // Continue with Google button
              _buildSignUpButton(
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                backgroundColor: AppColors.backgroundWhite,
                textColor: AppColors.textSecondary,
                iconColor: AppColors.textSecondary,
                borderColor: AppColors.backgroundGrey,
                onPressed: isLoading
                    ? () {}
                    : () {
                        context.read<AuthCubit>().signInWithGoogle();
                      },
              ),
              const SizedBox(height: AppResources.spacingM),

              // Continue with Apple button
              _buildSignUpButton(
                icon: Icons.apple,
                label: 'Continue with Apple',
                backgroundColor: AppColors.textPrimary,
                textColor: AppColors.textOnPrimary,
                iconColor: AppColors.textOnPrimary,
                onPressed: () {
                  // TODO: Implement Apple sign in
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Apple sign in coming soon')),
                  );
                },
              ),
              const SizedBox(height: AppResources.spacingXXL),

              // Login prompt
              Center(
                child: RichText(
                  text: TextSpan(
                    style: AppFonts.body(color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const SignInPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Log in',
                            style: AppFonts.body(color: AppColors.brandSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignUpButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    Color? borderColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: AppResources.buttonHeightM,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          side: borderColor != null
              ? BorderSide(color: borderColor, width: 1)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppResources.radiusM),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: AppResources.iconSizeM),
            const SizedBox(width: AppResources.spacingM),
            Text(
              label,
              style: AppFonts.button(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
