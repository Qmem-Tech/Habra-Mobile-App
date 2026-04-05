import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import 'add_new_presence_page.dart';

/// Shown when a business owner has completed intro onboarding but has no listings yet.
/// Primary path: Add New Presence → full create-business flow.
class BusinessOwnerFirstListingPage extends StatelessWidget {
  const BusinessOwnerFirstListingPage({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        title: Text(
          'List your business',
          style: AppFonts.mediumTitle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.read<AuthCubit>().logout(),
            child: Text(
              'Sign out',
              style: AppFonts.body(color: AppColors.brandPrimary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingL,
            vertical: AppResources.spacingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppResources.spacingL),
              Text(
                'Add your first presence on Habra',
                style: AppFonts.largeTitle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppResources.spacingM),
              Text(
                'Tell us about your business—location, contact details, photos, and '
                'verification documents. After you submit, your listing will be pending '
                'review before it appears to the community.',
                style: AppFonts.body(color: AppColors.textSecondary),
              ),
              if (user.email.isNotEmpty) ...[
                const SizedBox(height: AppResources.spacingL),
                Text(
                  'Signed in as ${user.email}',
                  style: AppFonts.caption(color: AppColors.textTertiary),
                ),
              ],
              const Spacer(),
              AppButton(
                text: 'Add new presence',
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddNewPresencePage(
                        presences: [],
                        isFirstListingSetup: true,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppResources.spacingM),
            ],
          ),
        ),
      ),
    );
  }
}
