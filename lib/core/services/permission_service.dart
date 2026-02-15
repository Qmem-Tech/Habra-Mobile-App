import 'package:permission_handler/permission_handler.dart';

import '../permissions/app_permission.dart';
import '../widgets/permission_request_dialog.dart';

import 'package:flutter/material.dart';

/// Service for checking and requesting app permissions with Habra-themed UI.
class PermissionService {
  PermissionService();

  /// Check if permission is granted.
  Future<bool> isGranted(AppPermission appPermission) async {
    final status = await appPermission.permission.status;
    return status.isGranted;
  }

  /// Check if permission is permanently denied (user must go to settings).
  Future<bool> isPermanentlyDenied(AppPermission appPermission) async {
    final status = await appPermission.permission.status;
    return status.isPermanentlyDenied;
  }

  /// Request permission. Shows Habra dialog first if not granted.
  /// Returns true if granted, false otherwise.
  Future<bool> requestWithDialog(
    BuildContext context,
    AppPermission appPermission, {
    String? customSubtitle,
  }) async {
    if (await isGranted(appPermission)) return true;
    if (!context.mounted) return false;

    final shouldRequest = await PermissionRequestDialog.showForPermission(
      context,
      appPermission,
      customSubtitle: customSubtitle,
    );

    if (!shouldRequest || !context.mounted) return false;

    final status = await appPermission.permission.request();
    return status.isGranted;
  }

  /// Request multiple permissions. Shows dialog with list, then requests each.
  /// Returns true if all granted.
  Future<bool> requestMultipleWithDialog(
    BuildContext context,
    List<AppPermission> permissions, {
    String title = 'Permissions Needed',
    String? subtitle,
  }) async {
    final notGranted = <AppPermission>[];
    for (final p in permissions) {
      if (!await isGranted(p)) notGranted.add(p);
    }
    if (notGranted.isEmpty) return true;
    if (!context.mounted) return false;

    final shouldRequest = await PermissionRequestDialog.show(
      context,
      permissions: notGranted,
      title: title,
      subtitle: subtitle ??
          'Habra needs these permissions to give you the best experience.',
      allowButtonText: 'Allow All',
    );

    if (!shouldRequest || !context.mounted) return false;

    bool allGranted = true;
    for (final p in notGranted) {
      final status = await p.permission.request();
      if (!status.isGranted) allGranted = false;
    }
    return allGranted;
  }

  /// Request permission directly (no dialog). For internal use.
  Future<bool> request(AppPermission appPermission) async {
    final status = await appPermission.permission.request();
    return status.isGranted;
  }

  /// Open app settings so user can manually enable.
  Future<bool> openSettings() async {
    return openAppSettings();
  }
}
