import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/navigation/main_navigation_wrapper.dart';
import '../pages/auth_callback_verification_page.dart';
import '../pages/reset_password_page.dart';

/// Listens to Supabase auth state and incoming auth deep links for the app lifetime.
///
/// Must wrap the [MaterialApp] navigator (via `builder`), not only the splash route,
/// so password-recovery navigation still works after the user leaves splash.
class AuthDeepLinkHandler extends StatefulWidget {
  const AuthDeepLinkHandler({super.key, required this.child});

  final Widget child;

  @override
  State<AuthDeepLinkHandler> createState() => _AuthDeepLinkHandlerState();
}

class _AuthDeepLinkHandlerState extends State<AuthDeepLinkHandler> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _hasHandledEmailVerificationNavigation = false;

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
    if (state.event == AuthChangeEvent.passwordRecovery) {
      _navigateToResetPassword();
      return;
    }

    if (_hasHandledEmailVerificationNavigation) return;

    if (state.event == AuthChangeEvent.signedIn ||
        state.event == AuthChangeEvent.initialSession ||
        state.event == AuthChangeEvent.tokenRefreshed ||
        state.event == AuthChangeEvent.userUpdated) {
      _maybeHandleEmailVerificationCallback(state.session);
    }
  }

  void _navigateToResetPassword() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = mainNavigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const ResetPasswordPage()),
        (_) => false,
      );
    });
  }

  Future<void> _maybeHandleEmailVerificationCallback(Session? session) async {
    if (session == null) return;
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

    _hasHandledEmailVerificationNavigation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = mainNavigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const AuthCallbackVerificationPage(),
        ),
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
