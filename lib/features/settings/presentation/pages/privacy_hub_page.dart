import 'package:flutter/material.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/permission_list_page.dart';
import 'privacy_policy_page.dart';

/// Entry point for privacy-related options (app permissions + policy).
class PrivacyHubPage extends StatelessWidget {
  const PrivacyHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Privacy',
          style: AppFonts.mediumTitle(color: AppColors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppResources.spacingM),
        children: [
          _Tile(
            icon: Icons.phonelink_lock_outlined,
            title: 'App permissions',
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const PermissionListPage(),
                ),
              );
            },
          ),
          const SizedBox(height: AppResources.spacingS),
          _Tile(
            icon: Icons.policy_outlined,
            title: 'Privacy policy',
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacyPolicyPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundLight,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingM,
            vertical: AppResources.spacingM,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.settingsIconTileBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.ownerHomePrimary, size: 22),
              ),
              const SizedBox(width: AppResources.spacingM),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.body(color: AppColors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
