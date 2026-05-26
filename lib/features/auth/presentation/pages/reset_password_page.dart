import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import 'sign_in_page.dart';

/// Shown when user opens the app via the password reset link (recovery session).
/// User enters new password; on success, session is cleared and user is sent to sign in.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().updatePassword(_newPasswordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is AuthUnauthenticated ||
            state is AuthPasswordUpdated) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SignInPage()),
            (route) => false,
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
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return SingleChildScrollView(
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
                        'Create new password',
                        style: AppFonts.largeTitle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppResources.spacingM),

                      // Description
                      Text(
                        'Your new password must be different from previous passwords.',
                        style:
                            AppFonts.body(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppResources.spacingXXL),

                      // New Password field
                      Text(
                        'New Password',
                        style: AppFonts.body(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppResources.spacingS),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          hintText: 'New Password',
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
                              _obscureNewPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your new password';
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
                        obscureText: _obscureConfirmPassword,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
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
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppResources.spacingXXL),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        height: AppResources.buttonHeightM,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _onConfirm,
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  'Confirm',
                                  style: AppFonts.button(
                                          color: AppColors.textOnPrimary)
                                      .copyWith(height: 1.0),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
