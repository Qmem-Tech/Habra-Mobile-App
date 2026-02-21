import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'profile_page.dart';

/// Profile tab content for the main bottom nav. Shows ProfilePage when authenticated.
class ProfileTabPage extends StatelessWidget {
  final User? user;

  const ProfileTabPage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (previous, current) =>
          previous is AuthAuthenticated != current is AuthAuthenticated ||
          (current is AuthAuthenticated && previous is AuthAuthenticated &&
              current.user != previous.user),
      builder: (context, state) {
        final effectiveUser = user ?? (state is AuthAuthenticated ? state.user : null);
        if (effectiveUser != null) {
          return ProfilePage(user: effectiveUser);
        }
        return const _ProfilePlaceholder();
      },
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Sign in to view your profile',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
