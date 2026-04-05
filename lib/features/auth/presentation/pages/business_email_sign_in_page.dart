import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../../../home/presentation/pages/admin_home_page.dart';
import '../../../home/presentation/pages/business_owner_wrapper_page.dart';
import '../../../home/presentation/pages/customer_home_page.dart';
import 'email_sign_up_page.dart';
import 'email_verification_page.dart';
import 'forgot_password_page.dart';
import 'wrong_path_page.dart';

/// Email + password sign-in for business owners (pushed from [BusinessSignInPage] hub).
class BusinessEmailSignInPage extends StatefulWidget {
  const BusinessEmailSignInPage({super.key});

  @override
  State<BusinessEmailSignInPage> createState() => _BusinessEmailSignInPageState();
}

class _BusinessEmailSignInPageState extends State<BusinessEmailSignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
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
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppResources.spacingL,
                    vertical: AppResources.spacingM,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign in with email',
                          style: AppFonts.largeTitle(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppResources.spacingM),
                        Text(
                          'Use the email and password for your business account.',
                          style: AppFonts.body(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppResources.spacingXL),
                        Text(
                          'Email',
                          style: AppFonts.body(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppResources.spacingS),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            hintText: 'email@example.com',
                            hintStyle: AppFonts.body(color: AppColors.textTertiary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppResources.radiusM),
                              borderSide: const BorderSide(color: AppColors.backgroundGrey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppResources.radiusM),
                              borderSide: const BorderSide(color: AppColors.backgroundGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppResources.radiusM),
                              borderSide: const BorderSide(color: AppColors.brandPrimary),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppResources.spacingL),
                        Text(
                          'Password',
                          style: AppFonts.body(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppResources.spacingS),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !isLoading,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: AppFonts.body(color: AppColors.textTertiary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppResources.radiusM),
                              borderSide: const BorderSide(color: AppColors.backgroundGrey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppResources.radiusM),
                              borderSide: const BorderSide(color: AppColors.backgroundGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppResources.radiusM),
                              borderSide: const BorderSide(color: AppColors.brandPrimary),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppResources.spacingM),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot password',
                              style: AppFonts.bodySmall(color: AppColors.brandSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppResources.spacingL),
                        SizedBox(
                          width: double.infinity,
                          height: AppResources.buttonHeightM,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      context.read<AuthCubit>().login(
                                            _emailController.text.trim(),
                                            _passwordController.text,
                                          );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                              foregroundColor: AppColors.textOnPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppResources.radiusM),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textOnPrimary,
                                    ),
                                  )
                                : Text(
                                    'Log in',
                                    style: AppFonts.button(color: AppColors.textOnPrimary),
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppResources.spacingXL),
                        Center(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EmailSignUpPage(
                                    selectedRole: UserRole.businessOwner,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(AppResources.spacingS),
                              child: Text.rich(
                                TextSpan(
                                  style: AppFonts.body(color: AppColors.textSecondary),
                                  children: [
                                    const TextSpan(text: 'New business? '),
                                    TextSpan(
                                      text: 'Sign up',
                                      style: AppFonts.body(color: AppColors.brandSecondary)
                                          .copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
