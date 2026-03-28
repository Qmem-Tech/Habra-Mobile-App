import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_mail_launcher/open_mail_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import 'auth_callback_verification_page.dart';
import 'business_sign_in_page.dart';
import 'sign_in_page.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../utils/auth_session_sync.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({
    super.key,
    required this.email,
    this.signUpRole = UserRole.customer,
  });

  final String email;
  final UserRole signUpRole;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  int _resendCooldownSeconds = 0;
  Timer? _cooldownTimer;
  Timer? _autoCheckTimer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
    _startAutoVerificationCheck();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _openEmailApp(BuildContext context) async {
    try {
      // Open the mail app to inbox (no compose / mailto)
      final result = await OpenMailLauncher.openMailApp();
      if (!result.didOpen && context.mounted) {
        _showOpenEmailFallback(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showOpenEmailFallback(context);
      }
    }
  }

  Future<void> _exitVerificationFlow() async {
    final navigator = Navigator.of(context);
    final authCubit = context.read<AuthCubit>();
    await authCubit.logout();
    if (!mounted) return;
    authCubit.resetToInitial();
    if (!mounted) return;
    final Widget root = widget.signUpRole == UserRole.businessOwner
        ? const BusinessSignInPage()
        : const SignInPage();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => root),
      (route) => false,
    );
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
    if (_isResending || _resendCooldownSeconds > 0) return;
    setState(() => _isResending = true);
    context.read<AuthCubit>().resendVerificationEmail(widget.email);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthResendVerificationSuccess) {
          if (mounted) {
            setState(() => _isResending = false);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification email sent to ${widget.email}. Check your inbox.'),
            ),
          );
          _startResendCooldown();
        } else if (state is AuthError) {
          if (mounted) {
            setState(() => _isResending = false);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is AuthEmailVerificationPending) {
          if (mounted) {
            setState(() => _isResending = false);
          }
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
            onPressed: _exitVerificationFlow,
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
                  'We sent a verification email to ${widget.email}. Open the link on your phone or computer—then return here and tap "I verified, continue", or sign in again.',
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
                    onPressed: (_resendCooldownSeconds > 0 || _isResending)
                        ? null
                        : _onResendTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: (_resendCooldownSeconds > 0 || _isResending)
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.backgroundGrey),
                      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                      ),
                    ),
                    child: Text(
                      _isResending
                          ? 'Sending...'
                          : _resendCooldownSeconds > 0
                          ? 'Resend in 0:${_resendCooldownSeconds.toString().padLeft(2, '0')}'
                          : 'Resend email',
                      style: AppFonts.button(
                        color: (_resendCooldownSeconds > 0 || _isResending)
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ).copyWith(height: 1.0),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: AppResources.spacingL),
                TextButton(
                  onPressed: () {
                    _onVerifiedContinue();
                  },
                  child: Text(
                    'I verified, continue',
                    style: AppFonts.body(color: AppColors.brandPrimary),
                  ),
                ),
                const SizedBox(height: AppResources.spacingS),
                TextButton(
                  onPressed: _exitVerificationFlow,
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

  Future<void> _onVerifiedContinue() async {
    final messenger = ScaffoldMessenger.of(context);
    await tryRefreshSupabaseSession();
    if (!mounted) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'No active session on this device. If you verified in a browser, use Back to sign in and log in with your email and password.',
            ),
          ),
        );
        return;
      }
      final isEmailVerified = user.emailConfirmedAt != null;
      if (!isEmailVerified) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Email is not verified yet. If you opened the link on another device, wait a moment and try again—or sign in after verifying.',
            ),
          ),
        );
        return;
      }
      await Supabase.instance.client
          .from('profiles')
          .update({'email_verified_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AuthCallbackVerificationPage(),
        ),
        (route) => false,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not verify status. Please try again in a few seconds.'),
        ),
      );
    }
  }

  void _startAutoVerificationCheck() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) {
        _autoCheckTimer?.cancel();
        return;
      }
      await tryRefreshSupabaseSession();
      if (!mounted) return;
      final user = Supabase.instance.client.auth.currentUser;
      if (user?.emailConfirmedAt == null) return;
      _autoCheckTimer?.cancel();
      await _onVerifiedContinue();
    });
  }
}
