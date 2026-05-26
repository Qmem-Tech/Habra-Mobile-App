import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../permissions/app_permission.dart';
import '../widgets/permission_request_dialog.dart';

/// Service for checking and requesting app permissions with Habra-themed UI.
class PermissionService {
  PermissionService();

  static bool _useGeolocatorForLocationOnIos(AppPermission p) =>
      p == AppPermission.location &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Photos: iOS 14+ / Android 14+ can return [PermissionStatus.limited] (partial
  /// library). That is still enough to pick images — [PermissionStatus.isGranted]
  /// alone would wrongly block those users.
  static bool _hasAccess(AppPermission appPermission, PermissionStatus status) {
    if (appPermission == AppPermission.photos) {
      return status.isGranted || status.isLimited;
    }
    return status.isGranted;
  }

  /// Check if permission is granted.
  Future<bool> isGranted(AppPermission appPermission) async {
    if (_useGeolocatorForLocationOnIos(appPermission)) {
      final s = await Geolocator.checkPermission();
      return s == LocationPermission.whileInUse || s == LocationPermission.always;
    }
    final status = await appPermission.permission.status;
    return _hasAccess(appPermission, status);
  }

  /// Check if permission is permanently denied (user must go to settings).
  Future<bool> isPermanentlyDenied(AppPermission appPermission) async {
    if (_useGeolocatorForLocationOnIos(appPermission)) {
      final s = await Geolocator.checkPermission();
      return s == LocationPermission.deniedForever;
    }
    final status = await appPermission.permission.status;
    return status.isPermanentlyDenied;
  }

  /// iOS: use Core Location via Geolocator so status matches [getCurrentPosition].
  /// permission_handler only reports location correctly when Pod macros are set;
  /// Geolocator always uses the same native path as actual fixes.
  Future<bool> _requestIosLocationViaGeolocator() async {
    var s = await Geolocator.checkPermission();
    if (s == LocationPermission.deniedForever) return false;
    if (s == LocationPermission.whileInUse || s == LocationPermission.always) {
      return true;
    }
    if (s == LocationPermission.denied || s == LocationPermission.unableToDetermine) {
      s = await Geolocator.requestPermission();
    }
    if (s == LocationPermission.whileInUse || s == LocationPermission.always) {
      return true;
    }
    for (var i = 0; i < 15; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      s = await Geolocator.checkPermission();
      if (s == LocationPermission.whileInUse || s == LocationPermission.always) {
        return true;
      }
      if (s == LocationPermission.deniedForever) return false;
    }
    return false;
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

    // Dismissing our modal bottom sheet and immediately calling the native
    // permission API can fail to show the system dialog (especially on iOS).
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!context.mounted) return false;

    if (_useGeolocatorForLocationOnIos(appPermission)) {
      return _requestIosLocationViaGeolocator();
    }

    var status = await appPermission.permission.request();
    if (_hasAccess(appPermission, status)) return true;
    // iOS: status can lag one frame after the user taps Allow on the system sheet.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    status = await appPermission.permission.status;
    return _hasAccess(appPermission, status);
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
      if (_useGeolocatorForLocationOnIos(p)) {
        if (!await _requestIosLocationViaGeolocator()) allGranted = false;
      } else {
        final status = await p.permission.request();
        if (!_hasAccess(p, status)) allGranted = false;
      }
    }
    return allGranted;
  }

  /// Request permission directly (no dialog). For internal use.
  Future<bool> request(AppPermission appPermission) async {
    if (_useGeolocatorForLocationOnIos(appPermission)) {
      return _requestIosLocationViaGeolocator();
    }
    final status = await appPermission.permission.request();
    return _hasAccess(appPermission, status);
  }

  /// Open app settings so user can manually enable.
  Future<bool> openSettings() async {
    return openAppSettings();
  }
}
