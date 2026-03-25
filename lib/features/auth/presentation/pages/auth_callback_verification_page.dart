import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../splash/presentation/pages/splash_page.dart';

class AuthCallbackVerificationPage extends StatefulWidget {
  const AuthCallbackVerificationPage({super.key});

  @override
  State<AuthCallbackVerificationPage> createState() =>
      _AuthCallbackVerificationPageState();
}

class _AuthCallbackVerificationPageState
    extends State<AuthCallbackVerificationPage> {
  bool _isLoading = true;
  bool _isVerified = false;
  String? _message;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  static const int _maxPollAttempts = 15; // ~30 seconds at 2s interval

  @override
  void initState() {
    super.initState();
    _checkVerification();
    _startVerificationPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final isEmailVerified = user?.emailConfirmedAt != null;
      if (!isEmailVerified || user == null) {
        setState(() {
          _isVerified = false;
          _isLoading = false;
          _message = 'Email is not verified yet. Please open the link in your inbox first.';
        });
        return;
      }

      await Supabase.instance.client
          .from('profiles')
          .update({'email_verified_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);

      _pollTimer?.cancel();
      setState(() {
        _isVerified = true;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isVerified = false;
        _isLoading = false;
        _message = 'Could not verify your account status. Please try again.';
      });
    }
  }

  void _continue() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashPage()),
      (route) => false,
    );
  }

  void _startVerificationPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || _isVerified) {
        _pollTimer?.cancel();
        return;
      }
      _pollAttempts++;
      await _checkVerification();
      if (_pollAttempts >= _maxPollAttempts && !_isVerified) {
        _pollTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _message = 'Still waiting for verification callback. If you opened in browser, return to app and tap Check Again.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingL),
            child: _isLoading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppResources.spacingL),
                      Text(
                        'Checking your verification status...',
                        style: AppFonts.body(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isVerified ? Icons.check_circle : Icons.error_outline,
                        size: 88,
                        color: _isVerified ? Colors.green : AppColors.error,
                      ),
                      const SizedBox(height: AppResources.spacingL),
                      Text(
                        _isVerified
                            ? 'Email Verified Successfully'
                            : 'Verification Pending',
                        style: AppFonts.largeTitle(color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppResources.spacingM),
                      Text(
                        _isVerified
                            ? 'Great! Your account is verified. Tap continue to proceed.'
                            : (_message ?? 'Please verify your email and try again.'),
                        style: AppFonts.body(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppResources.spacingXL),
                      SizedBox(
                        width: double.infinity,
                        height: AppResources.buttonHeightM,
                        child: ElevatedButton(
                          onPressed: _isVerified ? _continue : _checkVerification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: AppColors.textOnPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusM),
                            ),
                          ),
                          child: Text(
                            _isVerified ? 'Continue' : 'Check Again',
                            style: AppFonts.button(color: AppColors.textOnPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
