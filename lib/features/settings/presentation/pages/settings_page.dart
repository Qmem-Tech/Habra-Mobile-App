import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habra_mobile_app/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/permission_list_page.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/sign_in_page.dart';
import '../../../../core/localization/localization_cubit.dart' as loc;
import 'language_page.dart';
import 'terms_of_service_page.dart';
import 'privacy_policy_page.dart';
import 'community_guidelines_page.dart';
import 'about_us_page.dart';
import '../../../feedback/presentation/bloc/feedback_cubit.dart';
import '../../../feedback/presentation/pages/feedback_page.dart';
import '../../../home/presentation/pages/edit_profile_page.dart';
import '../../../profile/presentation/bloc/edit_profile_cubit.dart';
import '../../../../injection/injection_container.dart' as di;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthAuthenticated ? authState.user : null;
          return ListView(
            padding: const EdgeInsets.all(AppResources.spacingM),
            children: [
              if (user != null) _ProfileCard(user: user),
              const SizedBox(height: AppResources.spacingL),
              _SectionTitle(title: 'Preferences'),
              _SettingsTile(
                icon: Icons.language,
                title: l10n.language,
                trailing: BlocBuilder<loc.LocalizationCubit, loc.LocalizationState>(
                  builder: (context, state) {
                    return Text(
                      _languageName(state.locale.languageCode),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    );
                  },
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LanguagePage(),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.location_on_outlined,
                title: 'Location Settings',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PermissionListPage(),
                  ),
                ),
              ),
              const SizedBox(height: AppResources.spacingL),
              _SectionTitle(title: 'Notifications'),
              _SettingsTileWithSwitch(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                value: true,
                onChanged: (v) {},
              ),
              const SizedBox(height: AppResources.spacingL),
              _SectionTitle(title: 'Privacy & Support'),
              _SettingsTile(
                icon: Icons.feedback_outlined,
                title: 'Feedback',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => di.sl<FeedbackCubit>(),
                      child: const FeedbackPage(),
                    ),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.people_outline,
                title: 'Community Guidelines',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CommunityGuidelinesPage(),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.policy_outlined,
                title: 'Privacy Policy',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyPage(),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermsOfServicePage(),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'About Us',
                trailing: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.hasData ? 'v${snapshot.data!.version}' : '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    );
                  },
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutUsPage(),
                  ),
                ),
              ),
              const SizedBox(height: AppResources.spacingXL),
              _LogoutButton(
                onTap: () => _logout(context),
              ),
            ],
          );
        },
      ),
    );
  }

  String _languageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'am':
        return 'Amharic';
      case 'ti':
        return 'Tigrinya';
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  void _logout(BuildContext context) {
    context.read<AuthCubit>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final User user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.name;
    final email = user.email;

    return Container(
      margin: const EdgeInsets.only(bottom: AppResources.spacingM),
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => di.sl<EditProfileCubit>(),
                child: EditProfilePage(user: user),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppResources.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Edit Profile',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppResources.spacingS,
        bottom: AppResources.spacingS,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppResources.spacingS),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.brandPrimary, size: 24),
        title: Text(title),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsTileWithSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTileWithSwitch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppResources.spacingS),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.brandPrimary, size: 24),
        title: Text(title),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.brandPrimary,
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppResources.buttonHeightL,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppResources.radiusM),
          ),
        ),
        child: const Text('Log Out'),
      ),
    );
  }
}
