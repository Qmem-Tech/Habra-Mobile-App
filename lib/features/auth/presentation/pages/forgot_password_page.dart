import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_mail_launcher/open_mail_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import 'reset_password_page.dart';
import 'sign_in_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  StreamSubscription<supa.AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        supa.Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == supa.AuthChangeEvent.passwordRecovery && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const ResetPasswordPage()),
          (_) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _onReset() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().resetPasswordForEmail(
            _emailController.text.trim(),
          );
    }
  }

  Future<void> _openEmailApp() async {
    try {
      final result = await OpenMailLauncher.openMailApp();
      if (!result.didOpen && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please open your email app and check the inbox for ${_emailController.text.trim()}',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check your email app for the reset link'),
          ),
        );
      }
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
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final emailSent = state is AuthResetEmailSent;

        if (emailSent) {
          return _buildEmailSentUI();
        }

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
          body: SafeArea(
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
                    const SizedBox(height: AppResources.spacingXXL),

                    // Title
                    Text(
                      'Reset your password',
                      style: AppFonts.largeTitle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppResources.spacingM),

                    // Description
                    Text(
                      'Enter the email address associated with your account. We\'ll send you a link to reset your password.',
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
                          borderRadius:
                              BorderRadius.circular(AppResources.radiusM),
                          borderSide: BorderSide(color: AppColors.backgroundGrey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppResources.radiusM),
                          borderSide: BorderSide(color: AppColors.backgroundGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppResources.radiusM),
                          borderSide:
                              const BorderSide(color: AppColors.brandPrimary),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppResources.spacingXXL),

                    // Reset button
                    SizedBox(
                      width: double.infinity,
                      height: AppResources.buttonHeightM,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _onReset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: AppColors.textOnPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppResources.spacingM,
                          ),
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
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Send reset link',
                                style: AppFonts.button(
                                  color: AppColors.textOnPrimary,
                                ).copyWith(height: 1.0),
                                textAlign: TextAlign.center,
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

  Widget _buildEmailSentUI() {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingL,
            vertical: AppResources.spacingM,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppResources.spacingXXL),
              Icon(
                Icons.mark_email_read_outlined,
                size: 80,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(height: AppResources.spacingXXL),
              Text(
                'Check your email',
                style: AppFonts.largeTitle(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppResources.spacingM),
              Text(
                'We sent a password reset link to ${_emailController.text.trim()}. Tap the link in that email to set a new password.',
                style: AppFonts.body(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppResources.spacingXXL),
              SizedBox(
                width: double.infinity,
                height: AppResources.buttonHeightM,
                child: ElevatedButton(
                  onPressed: _openEmailApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppResources.spacingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppResources.radiusM),
                    ),
                  ),
                  child: Text(
                    'Open email app',
                    style: AppFonts.button(color: AppColors.textOnPrimary)
                        .copyWith(height: 1.0),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: AppResources.spacingM),
              TextButton(
                onPressed: () {
                  context.read<AuthCubit>().resetToInitial();
                },
                child: Text(
                  'Try different email',
                  style: AppFonts.body(color: AppColors.brandPrimary),
                ),
              ),
              const SizedBox(height: AppResources.spacingL),
              TextButton(
                onPressed: () {
                  context.read<AuthCubit>().resetToInitial();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignInPage()),
                    (route) => false,
                  );
                },
                child: Text(
                  'Back to sign in',
                  style: AppFonts.body(color: AppColors.brandPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
