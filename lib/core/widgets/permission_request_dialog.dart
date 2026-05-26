import 'package:flutter/material.dart';

import '../permissions/app_permission.dart';
import '../resources/app_resources.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_button.dart';

/// Beautiful Habra-themed permission request dialog.
///
/// Shows a list of permissions with gold-accented icons and descriptions.
/// Use [PermissionRequestDialog.show] to present.
class PermissionRequestDialog extends StatelessWidget {
  const PermissionRequestDialog({
    super.key,
    required this.permissions,
    this.title = 'Permissions Needed',
    this.subtitle =
        'Habra needs these permissions to give you the best experience.',
    this.allowButtonText = 'Allow',
    this.denyButtonText = 'Not Now',
    this.onAllow,
    this.onDeny,
  });

  final List<AppPermission> permissions;
  final String title;
  final String subtitle;
  final String allowButtonText;
  final String denyButtonText;
  final VoidCallback? onAllow;
  final VoidCallback? onDeny;

  /// Show the dialog for the given permissions.
  /// Returns true if user tapped Allow, false if Deny.
  static Future<bool> show(
    BuildContext context, {
    required List<AppPermission> permissions,
    String title = 'Permissions Needed',
    String subtitle =
        'Habra needs these permissions to give you the best experience.',
    String allowButtonText = 'Allow',
    String denyButtonText = 'Not Now',
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PermissionRequestDialog(
        permissions: permissions,
        title: title,
        subtitle: subtitle,
        allowButtonText: allowButtonText,
        denyButtonText: denyButtonText,
        onAllow: () => Navigator.pop(context, true),
        onDeny: () => Navigator.pop(context, false),
      ),
    );
    return result ?? false;
  }

  /// Show when a specific permission is needed (e.g. before camera use).
  static Future<bool> showForPermission(
    BuildContext context,
    AppPermission permission, {
    String? customSubtitle,
  }) async {
    return show(
      context,
      permissions: [permission],
      title: '${permission.title} Access',
      subtitle: customSubtitle ?? permission.description,
      allowButtonText: 'Allow ${permission.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppResources.spacingL,
            AppResources.spacingL,
            AppResources.spacingL,
            AppResources.spacingXL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHandle(),
              const SizedBox(height: AppResources.spacingM),
              Text(
                title,
                style: AppFonts.largeTitle(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppResources.spacingS),
              Text(
                subtitle,
                style: AppFonts.body(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppResources.spacingXL),
              _buildPermissionList(),
              const SizedBox(height: AppResources.spacingXL),
              AppButton(
                text: allowButtonText,
                onPressed: () {
                  onAllow?.call();
                },
              ),
              const SizedBox(height: AppResources.spacingS),
              Center(
                child: TextButton(
                  onPressed: () {
                    onDeny?.call();
                  },
                  child: Text(
                    denyButtonText,
                    style: AppFonts.body(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildPermissionList() {
    return Column(
      children: permissions
          .map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppResources.spacingM),
              child: _PermissionItem(permission: p),
            ),
          )
          .toList(),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  const _PermissionItem({required this.permission});

  final AppPermission permission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.brandSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        border: Border.all(
          color: AppColors.brandSecondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brandSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppResources.radiusM),
            ),
            child: Icon(
              permission.icon,
              size: 28,
              color: AppColors.brandSecondaryDark,
            ),
          ),
          const SizedBox(width: AppResources.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission.title,
                  style: AppFonts.body(
                    color: AppColors.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  permission.description,
                  style: AppFonts.bodySmall(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
