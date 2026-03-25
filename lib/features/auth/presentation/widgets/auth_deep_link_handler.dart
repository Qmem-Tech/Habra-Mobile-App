import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/auth_callback_verification_page.dart';
import '../pages/reset_password_page.dart';

/// Listens to Supabase auth state changes and navigates to [ResetPasswordPage]
/// when the user opens the app via the password reset link (recovery flow).
class AuthDeepLinkHandler extends StatefulWidget {
  const AuthDeepLinkHandler({super.key, required this.child});

  final Widget child;

  @override
  State<AuthDeepLinkHandler> createState() => _AuthDeepLinkHandlerState();
}

class _AuthDeepLinkHandlerState extends State<AuthDeepLinkHandler> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _hasHandledAuthNavigation = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      _onAuthStateChange,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _onAuthStateChange(AuthState state) {
    if (_hasHandledAuthNavigation) return;

    if (state.event == AuthChangeEvent.passwordRecovery) {
      _hasHandledAuthNavigation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
          (route) => false,
        );
      });
      return;
    }

    if (state.event == AuthChangeEvent.signedIn ||
        state.event == AuthChangeEvent.initialSession ||
        state.event == AuthChangeEvent.tokenRefreshed ||
        state.event == AuthChangeEvent.userUpdated) {
      _maybeHandleEmailVerificationCallback(state.session);
    }
  }

  Future<void> _maybeHandleEmailVerificationCallback(Session? session) async {
    if (_hasHandledAuthNavigation || session == null) return;
    final isEmailVerified = session.user.emailConfirmedAt != null;
    if (!isEmailVerified) return;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('email_verified_at')
          .eq('id', session.user.id)
          .maybeSingle();
      final profileVerifiedAt = profile is Map<String, dynamic>
          ? profile['email_verified_at']
          : null;
      if (profileVerifiedAt != null) {
        return;
      }
    } catch (_) {
      // If profile lookup fails, still allow callback screen as fallback.
    }

    _hasHandledAuthNavigation = true;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthCallbackVerificationPage()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
