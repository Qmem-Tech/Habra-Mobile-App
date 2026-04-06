import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habra_mobile_app/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/account_settings_body.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.settings,
          style: AppFonts.mediumTitle(color: AppColors.textPrimary)
              .copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthAuthenticated ? authState.user : null;
          return AccountSettingsBody(user: user);
        },
      ),
    );
  }
}
