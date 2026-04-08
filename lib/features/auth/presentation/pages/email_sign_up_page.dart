import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../../domain/entities/user.dart';
import '../../../home/presentation/pages/business_owner_wrapper_page.dart';
import '../../../home/presentation/pages/admin_home_page.dart';
import '../../../home/presentation/pages/guest_home_page.dart';
import '../../../settings/presentation/pages/terms_of_service_page.dart';
import 'city_selection_page.dart';
import 'email_verification_page.dart';

class EmailSignUpPage extends StatefulWidget {
  const EmailSignUpPage({super.key, this.selectedRole = UserRole.customer});

  /// Role chosen on ChoosePathPage; used when registering.
  final UserRole selectedRole;

  @override
  State<EmailSignUpPage> createState() => _EmailSignUpPageState();
}

class _EmailSignUpPageState extends State<EmailSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        destination = const CitySelectionPage();
        break;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _onContinue(BuildContext context) {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      context.read<AuthCubit>().register(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
            widget.selectedRole,
          );
    } else if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please agree to the Terms and Conditions')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is AuthEmailVerificationPending) {
          if (!context.mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EmailVerificationPage(
                email: state.email,
                signUpRole: widget.selectedRole,
              ),
            ),
          );
        } else if (state is AuthAuthenticated) {
          _handleNavigationForUser(context, state.user);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColors.backgroundWhite,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundWhite,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
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

                        // Title: "Business account" when business owner journey, else "user account"
                        RichText(
                          text: TextSpan(
                            style: AppFonts.largeTitle(
                                color: AppColors.textPrimary),
                            children: [
                              TextSpan(
                                text: widget.selectedRole == UserRole.businessOwner
                                    ? 'Business '
                                    : 'user ',
                                style: AppFonts.largeTitle(
                                    color: AppColors.brandSecondary),
                              ),
                              const TextSpan(text: 'account'),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppResources.spacingS),
                        Text(
                          widget.selectedRole == UserRole.businessOwner
                              ? 'Create your business account'
                              : 'Create your user account',
                          style:
                              AppFonts.largeTitle(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppResources.spacingXXL),

                        // Full Name field
                        Text(
                          'Full Name',
                          style: AppFonts.body(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppResources.spacingS),
                        TextFormField(
                          controller: _nameController,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            hintText: 'Enter your full name',
                            hintStyle:
                                AppFonts.body(color: AppColors.textTertiary),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusM),
                              borderSide:
                                  BorderSide(color: AppColors.backgroundGrey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusM),
                              borderSide:
                                  BorderSide(color: AppColors.backgroundGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusM),
                              borderSide: const BorderSide(
                                  color: AppColors.brandPrimary),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppResources.spacingL),

                        // Email field
                        Text(
                          'Email',
                          style: AppFonts.body(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppResources.spacingS),
                        TextFormField(
                          controller: _emailController,
                          enabled: !isLoading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'email@example.com',
                            hintStyle:
                                AppFonts.body(color: AppColors.textTertiary),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusM),
                              borderSide:
                                  BorderSide(color: AppColors.backgroundGrey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusM),
                              borderSide:
                                  BorderSide(color: AppColors.backgroundGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusM),
                              borderSide: const BorderSide(
                                  color: AppColors.brandPrimary),
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
                          style: AppFonts.body(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppResources.spacingS),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !isLoading,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle:
                                AppFonts.body(color: AppColors.textTertiary),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusM),
                              borderSide:
                                  BorderSide(color: AppColors.backgroundGrey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusM),
                              borderSide:
                                  BorderSide(color: AppColors.backgroundGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusM),
                              borderSide: const BorderSide(
                                  color: AppColors.brandPrimary),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
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
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppResources.spacingL),

                        // Confirm Password field
                        Text(
                          'Confirm Password',
                          style: AppFonts.body(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppResources.spacingS),
                        TextFormField(
                          controller: _confirmPasswordController,
                          enabled: !isLoading,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            hintText: 'Confirm your password',
                            hintStyle:
                                AppFonts.body(color: AppColors.textTertiary),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusM),
                              borderSide:
                                  BorderSide(color: AppColors.backgroundGrey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusM),
                              borderSide:
                                  BorderSide(color: AppColors.backgroundGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusM),
                              borderSide: const BorderSide(
                                  color: AppColors.brandPrimary),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppResources.spacingL),

                        // Terms and Conditions checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              onChanged: isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _agreeToTerms = value ?? false;
                                      });
                                    },
                              activeColor: AppColors.brandPrimary,
                              checkColor: AppColors.textOnPrimary,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: AppResources.spacingM),
                                child: RichText(
                                  text: TextSpan(
                                    style: AppFonts.bodySmall(
                                        color: AppColors.textPrimary),
                                    children: [
                                      const TextSpan(text: 'I agree to the '),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => const TermsOfServicePage(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Terms and Conditions',
                                            style: AppFonts.bodySmall(
                                              color: AppColors.brandPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppResources.spacingL),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: AppResources.buttonHeightM,
                          child: ElevatedButton(
                            onPressed:
                                isLoading ? null : () => _onContinue(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                              foregroundColor: AppColors.textOnPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppResources.radiusM),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Continue',
                                    style: AppFonts.button(
                                        color: AppColors.textOnPrimary).copyWith(
                                      height: 1.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha:0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
