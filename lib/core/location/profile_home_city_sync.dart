import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/home/domain/entities/location_entity.dart';

/// Writes [location] to `profiles.city` for signed-in (non-guest) users so feeds
/// default to their chosen metro after registration or location picker.
Future<void> persistProfileHomeCityIfSignedIn(
  BuildContext context,
  LocationEntity location,
) async {
  if (!context.mounted) return;
  final authState = context.read<AuthCubit>().state;
  if (authState is! AuthAuthenticated || authState.user.isGuest) return;
  final label = location.fullDisplayName.trim();
  if (label.isEmpty) return;
  await context.read<AuthCubit>().saveHomeCity(label);
}
