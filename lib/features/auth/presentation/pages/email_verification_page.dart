import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key, required this.email});

  final String email;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  int _resendCooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _openEmailApp(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: widget.email);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showOpenEmailFallback(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showOpenEmailFallback(context);
      }
    }
  }

  void _showOpenEmailFallback(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open email app'),
        content: Text(
          'Please open your email app and check the inbox for the verification link sent to ${widget.email}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.email));
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email address copied to clipboard')),
                );
              }
            },
            child: const Text('Copy email'),
          ),
        ],
      ),
    );
  }

  void _startResendCooldown() {
    if (_resendCooldownSeconds > 0) return;
    setState(() => _resendCooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendCooldownSeconds <= 1) {
        _cooldownTimer?.cancel();
        setState(() => _resendCooldownSeconds = 0);
        return;
      }
      setState(() => _resendCooldownSeconds--);
    });
  }

  void _onResendTap() {
    context.read<AuthCubit>().resendVerificationEmail(widget.email);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthResendVerificationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification email resent. Check your inbox.')),
          );
          _startResendCooldown();
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
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
              Icons.close,
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
                _buildMailboxIllustration(),
                const SizedBox(height: AppResources.spacingXXL),
                Text(
                  'Check your email',
                  style: AppFonts.largeTitle(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppResources.spacingM),
                Text(
                  'We sent a verification email to ${widget.email}. Please tap the link inside that email to activate your account.',
                  style: AppFonts.body(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppResources.spacingXXL),
                SizedBox(
                  width: double.infinity,
                  height: AppResources.buttonHeightM,
                  child: ElevatedButton(
                    onPressed: () => _openEmailApp(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                      ),
                    ),
                    child: Text(
                      'Check my inbox',
                      style: AppFonts.button(color: AppColors.textOnPrimary).copyWith(
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: AppResources.spacingM),
                SizedBox(
                  width: double.infinity,
                  height: AppResources.buttonHeightM,
                  child: OutlinedButton(
                    onPressed: _resendCooldownSeconds > 0 ? null : _onResendTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _resendCooldownSeconds > 0
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.backgroundGrey),
                      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                      ),
                    ),
                    child: Text(
                      _resendCooldownSeconds > 0
                          ? 'Resend in 0:${_resendCooldownSeconds.toString().padLeft(2, '0')}'
                          : 'Resend email',
                      style: AppFonts.button(
                        color: _resendCooldownSeconds > 0
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ).copyWith(height: 1.0),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: AppResources.spacingL),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Back to sign in',
                    style: AppFonts.body(color: AppColors.brandPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMailboxIllustration() {
    return SizedBox(
      height: 200,
      child: Image.asset(
        'assets/illustration/mailbox.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.mail_outline,
          size: 120,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
