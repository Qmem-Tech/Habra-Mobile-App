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
import '../../../choose_path/presentation/pages/choose_path_page.dart';
import 'email_sign_up_page.dart';
import 'forgot_password_page.dart';

class BusinessSignInPage extends StatefulWidget {
  const BusinessSignInPage({super.key});

  @override
  State<BusinessSignInPage> createState() => _BusinessSignInPageState();
}

class _BusinessSignInPageState extends State<BusinessSignInPage> {
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
          child: BlocConsumer<AuthCubit, AuthState>(
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
                          const SizedBox(height: AppResources.spacingXL),

                          // Title with highlighted "Business"
                          RichText(
                            text: TextSpan(
                              style: AppFonts.largeTitle(color: AppColors.textPrimary),
                              children: [
                                TextSpan(
                                  text: 'Business ',
                                  style: AppFonts.largeTitle(color: AppColors.brandSecondary),
                                ),
                                const TextSpan(text: 'sign in'),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppResources.spacingM),

                          Text(
                            'Sign in with the same email you use for Habra. Your account type is determined by your profile.',
                            style: AppFonts.body(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppResources.spacingXXL),

                          // Email field
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
                                borderSide: BorderSide(color: AppColors.backgroundGrey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppResources.radiusM),
                                borderSide: BorderSide(color: AppColors.backgroundGrey),
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

                          // Password field
                          Text(
                            'Password',
                            style: AppFonts.body(color: AppColors.brandPrimary),
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
                                borderSide: const BorderSide(color: AppColors.brandPrimary),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppResources.radiusM),
                                borderSide: const BorderSide(color: AppColors.brandPrimary),
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
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
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

                          // Forgot password
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
                                style: AppFonts.bodySmall(color: AppColors.brandPrimary),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppResources.spacingL),

                          // Sign In button
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
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Sign In',
                                      style: AppFonts.button(color: AppColors.textOnPrimary),
                                    ),
                            ),
                          ),
                          const SizedBox(height: AppResources.spacingM),

                          // New business sign up - stay in business owner journey
                          Center(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EmailSignUpPage(
                                      selectedRole: UserRole.businessOwner,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppResources.spacingS,
                                  vertical: AppResources.spacingXS,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'New business? ',
                                      style: AppFonts.body(color: AppColors.textSecondary),
                                    ),
                                    Text(
                                      'Sign up',
                                      style: AppFonts.body(color: AppColors.brandPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppResources.spacingM),

                          // Different path - go back to choose path (community vs business)
                          Center(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const ChoosePathPage()),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppResources.spacingS,
                                  vertical: AppResources.spacingXS,
                                ),
                                child: Text(
                                  'Not a business owner? Choose a different path',
                                  style: AppFonts.bodySmall(color: AppColors.textSecondary),
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
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
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
