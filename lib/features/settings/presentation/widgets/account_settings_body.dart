import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habra_mobile_app/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/permission_list_page.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../auth/domain/entities/user.dart';
import '../../../feedback/presentation/bloc/feedback_cubit.dart';
import '../../../feedback/presentation/pages/feedback_page.dart';
import '../../../home/presentation/pages/edit_profile_page.dart';
import '../../../profile/presentation/bloc/edit_profile_cubit.dart';
import '../../../../core/localization/localization_cubit.dart' as loc;
import '../pages/about_us_page.dart';
import '../pages/community_guidelines_page.dart';
import '../pages/language_page.dart';
import '../pages/privacy_policy_page.dart';
import '../pages/terms_of_service_page.dart';
import 'account_danger_zone.dart';

/// Set to `true` when the profile language picker is ready to ship.
const bool _showLanguageSettingOnProfile = false;

/// Account / settings layout matching the Habra settings design mock.
class AccountSettingsBody extends StatefulWidget {
  const AccountSettingsBody({
    super.key,
    required this.user,
    this.displayNameOverride,
    this.avatarUrlOverride,
    this.onReturnedFromEditProfile,
  });

  final User? user;
  final String? displayNameOverride;
  final String? avatarUrlOverride;
  final VoidCallback? onReturnedFromEditProfile;

  @override
  State<AccountSettingsBody> createState() => _AccountSettingsBodyState();
}

class _AccountSettingsBodyState extends State<AccountSettingsBody> {
  final LocalStorage _storage = di.sl<LocalStorage>();
  bool _pushEnabled = true;
  bool _pushLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPushPref();
  }

  @override
  void didUpdateWidget(covariant AccountSettingsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.id != widget.user?.id) {
      _loadPushPref();
    }
  }

  Future<void> _loadPushPref() async {
    final id = widget.user?.id;
    if (id == null) {
      if (mounted) {
        setState(() {
          _pushLoading = false;
          _pushEnabled = true;
        });
      }
      return;
    }
    final key = _pushKey(id);
    final stored = await _storage.getBool(key);
    if (!mounted) return;
    setState(() {
      _pushEnabled = stored ?? true;
      _pushLoading = false;
    });
  }

  static String _pushKey(String userId) =>
      '${StorageKeys.ownerPushNotificationsEnabled}_$userId';

  Future<void> _onPushChanged(bool value) async {
    final id = widget.user?.id;
    if (id == null) return;
    setState(() => _pushEnabled = value);
    await _storage.setBool(_pushKey(id), value);
    final push = di.sl<PushNotificationService>();
    if (value) {
      await push.registerTokenForUser(id);
    } else {
      await push.clearTokenForUser(id);
    }
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

  Future<void> _openEditProfile(BuildContext context, User user) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<EditProfileCubit>(
          create: (_) => di.sl<EditProfileCubit>(),
          child: EditProfilePage(user: user),
        ),
      ),
    );
    if (!context.mounted) return;
    widget.onReturnedFromEditProfile?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = widget.user;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppResources.spacingM,
        AppResources.spacingS,
        AppResources.spacingM,
        AppResources.spacingXL,
      ),
      children: [
        if (user != null) ...[
          _ProfileCard(
            user: user,
            displayName: widget.displayNameOverride ?? user.name,
            avatarUrl: widget.avatarUrlOverride ?? user.avatarUrl,
            onTap: () => _openEditProfile(context, user),
          ),
          const SizedBox(height: AppResources.spacingL),
        ],
        _SectionTitle(title: 'Preferences'),
        if (_showLanguageSettingOnProfile) ...[
          _SettingsCard(
            child: _ChevronTile(
              icon: Icons.public_rounded,
              title: l10n.language,
              trailing: BlocBuilder<loc.LocalizationCubit, loc.LocalizationState>(
                builder: (context, state) {
                  return Text(
                    _languageName(state.locale.languageCode),
                    style: AppFonts.bodySmall(color: AppColors.textSecondary),
                  );
                },
              ),
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const LanguagePage()),
                );
              },
            ),
          ),
          const SizedBox(height: AppResources.spacingS),
        ],
        _SettingsCard(
          child: _ChevronTile(
            icon: Icons.location_on_outlined,
            title: 'Permissions Settings',
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const PermissionListPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppResources.spacingL),
        _SectionTitle(title: 'Notifications'),
        _SettingsCard(
          child: _pushLoading
              ? const Padding(
                  padding: EdgeInsets.all(AppResources.spacingM),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppResources.spacingS,
                    vertical: AppResources.spacingXS,
                  ),
                  child: Row(
                    children: [
                      _IconBadge(icon: Icons.notifications_outlined),
                      const SizedBox(width: AppResources.spacingS),
                      Expanded(
                        child: Text(
                          'Push Notifications',
                          style: AppFonts.body(color: AppColors.textPrimary)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Switch(
                        value: _pushEnabled,
                        onChanged:
                            widget.user == null ? null : _onPushChanged,
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.ownerHomePrimary;
                          }
                          return null;
                        }),
                        trackColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.ownerHomePrimary
                                .withValues(alpha: 0.45);
                          }
                          return null;
                        }),
                      ),
                    ],
                  ),
                ),
        ),
        if (user != null) ...[
          const SizedBox(height: AppResources.spacingS),
          _SettingsCard(
            child: _ChevronTile(
              icon: Icons.settings_suggest_outlined,
              title: 'System notification settings',
              onTap: () => openAppSettings(),
            ),
          ),
        ],
        const SizedBox(height: AppResources.spacingL),
        _SectionTitle(title: 'Privacy & Support'),
        _SettingsCard(
          child: Column(
            children: [
              _ChevronTile(
                icon: Icons.feedback_outlined,
                title: 'Feedback',
                showDividerBelow: true,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider<FeedbackCubit>(
                        create: (_) => di.sl<FeedbackCubit>(),
                        child: const FeedbackPage(),
                      ),
                    ),
                  );
                },
              ),
              _ChevronTile(
                icon: Icons.groups_outlined,
                title: 'Community Guidelines',
                showDividerBelow: true,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CommunityGuidelinesPage(),
                    ),
                  );
                },
              ),
              _ChevronTile(
                icon: Icons.help_outline_rounded,
                title: 'Privacy Policy',
                showDividerBelow: true,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
              _ChevronTile(
                icon: Icons.shield_outlined,
                title: 'Terms of Service',
                showDividerBelow: true,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const TermsOfServicePage(),
                    ),
                  );
                },
              ),
              _ChevronTile(
                icon: Icons.info_outline_rounded,
                title: 'About Us',
                trailing: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.hasData ? 'v${snapshot.data!.version}' : '',
                      style: AppFonts.bodySmall(color: AppColors.textSecondary),
                    );
                  },
                ),
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AboutUsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppResources.spacingXL),
        if (user != null) AccountDangerZone(user: user),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppResources.spacingXS,
        bottom: AppResources.spacingS,
      ),
      child: Text(
        title,
        style: AppFonts.bodySmall(color: AppColors.textSecondary)
            .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.settingsIconTileBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.ownerHomePrimary, size: 22),
    );
  }
}

class _ChevronTile extends StatelessWidget {
  const _ChevronTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.showDividerBelow = false,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDividerBelow;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppResources.spacingM,
                vertical: 14,
              ),
              child: Row(
                children: [
                  _IconBadge(icon: icon),
                  const SizedBox(width: AppResources.spacingM),
                  Expanded(
                    child: Text(
                      title,
                      style: AppFonts.body(color: AppColors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (trailing != null) ...[
                    trailing!,
                    const SizedBox(width: AppResources.spacingS),
                  ],
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDividerBelow)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 72),
            color: AppColors.backgroundWhite,
          ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.displayName,
    required this.avatarUrl,
    required this.onTap,
  });

  final User user;
  final String displayName;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final hasPhoto = url != null && url.isNotEmpty;

    return _SettingsCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppResources.spacingM),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor:
                      AppColors.settingsIconTileBackground,
                  backgroundImage:
                      hasPhoto ? NetworkImage(url) : null,
                  child: !hasPhoto
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: AppFonts.largeTitle(
                            color: AppColors.ownerHomePrimary,
                          ).copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: AppResources.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppFonts.body(color: AppColors.textPrimary)
                            .copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: AppFonts.bodySmall(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Edit Profile',
                        style: AppFonts.bodySmall(color: AppColors.ownerHomePrimary)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
