import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../permissions/app_permission.dart';
import '../resources/app_resources.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'permission_request_dialog.dart';

/// Full-page permission list with Habra theme.
///
/// Shows all app permissions with status, gold-accented icons,
/// and option to request or open settings.
class PermissionListPage extends StatefulWidget {
  const PermissionListPage({super.key});

  @override
  State<PermissionListPage> createState() => _PermissionListPageState();
}

class _PermissionListPageState extends State<PermissionListPage> {
  final Map<AppPermission, PermissionStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    _refreshStatuses();
  }

  Future<void> _refreshStatuses() async {
    final map = <AppPermission, PermissionStatus>{};
    for (final p in AppPermission.values) {
      map[p] = await p.permission.status;
    }
    if (mounted) {
      setState(() => _statuses.addAll(map));
    }
  }

  Future<void> _onPermissionTap(AppPermission p) async {
    final status = _statuses[p] ?? PermissionStatus.denied;

    if (status.isGranted) return;

    if (status.isPermanentlyDenied) {
      final open = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${p.title} Disabled'),
          content: Text(
            '${p.title} permission was denied. Open Settings to enable it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (open == true) {
        await openAppSettings();
        _refreshStatuses();
      }
      return;
    }

    final granted = await PermissionRequestDialog.showForPermission(context, p);
    if (granted) {
      await p.permission.request();
      _refreshStatuses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Permissions'),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStatuses,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppResources.spacingM),
        children: [
          _buildHeader(),
          const SizedBox(height: AppResources.spacingL),
          ...AppPermission.values.map((p) => _buildPermissionCard(p)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppResources.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppResources.radiusM),
                ),
                child: Icon(
                  Icons.security_rounded,
                  color: AppColors.brandSecondaryDark,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppResources.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Permissions',
                      style: AppFonts.mediumTitle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage what Habra can access on your device',
                      style: AppFonts.bodySmall(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(AppPermission p) {
    final status = _statuses[p] ?? PermissionStatus.denied;
    final isGranted = status.isGranted;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppResources.spacingM),
      child: Material(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        shadowColor: Colors.black.withValues(alpha: 0.05),
        elevation: 2,
        child: InkWell(
          onTap: () => _onPermissionTap(p),
          borderRadius: BorderRadius.circular(AppResources.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppResources.spacingM),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isGranted
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.brandSecondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppResources.radiusM),
                  ),
                  child: Icon(
                    p.icon,
                    size: 28,
                    color: isGranted
                        ? AppColors.success
                        : AppColors.brandSecondaryDark,
                  ),
                ),
                const SizedBox(width: AppResources.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: AppFonts.body(
                          color: AppColors.textPrimary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.description,
                        style: AppFonts.bodySmall(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppResources.spacingS),
                _buildStatusChip(status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(PermissionStatus status) {
    String label;
    Color color;
    switch (status) {
      case PermissionStatus.granted:
        label = 'Allowed';
        color = AppColors.success;
        break;
      case PermissionStatus.denied:
        label = 'Ask';
        color = AppColors.brandSecondaryDark;
        break;
      case PermissionStatus.permanentlyDenied:
        label = 'Settings';
        color = AppColors.warning;
        break;
      case PermissionStatus.restricted:
        label = 'Restricted';
        color = AppColors.textSecondary;
        break;
      case PermissionStatus.limited:
        label = 'Limited';
        color = AppColors.info;
        break;
      case PermissionStatus.provisional:
        label = 'Provisional';
        color = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppResources.spacingS,
        vertical: AppResources.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppFonts.caption(color: color).copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
