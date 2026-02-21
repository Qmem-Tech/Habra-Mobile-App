import 'package:flutter/material.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../auth/domain/entities/user.dart';

/// Profile tab content: shows current user profile data (in sync with auth).
class ProfilePage extends StatelessWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  static String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Community member';
      case UserRole.businessOwner:
        return 'Business owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.guest:
        return 'Guest';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: AppFonts.mediumTitle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingL,
            vertical: AppResources.spacingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppResources.spacingL),
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.2),
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name.substring(0, 1).toUpperCase()
                        : user.email.isNotEmpty
                            ? user.email.substring(0, 1).toUpperCase()
                            : '?',
                    style: AppFonts.largeTitle(color: AppColors.brandPrimary)
                        .copyWith(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: AppResources.spacingL),
              Text(
                user.name,
                style: AppFonts.mediumTitle(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppResources.spacingXS),
              Text(
                user.email,
                style: AppFonts.body(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppResources.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppResources.spacingM,
                  vertical: AppResources.spacingS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppResources.radiusM),
                ),
                child: Text(
                  _roleLabel(user.role),
                  style: AppFonts.bodySmall(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
