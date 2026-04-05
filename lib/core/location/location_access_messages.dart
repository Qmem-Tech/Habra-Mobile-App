import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Shared UX when GPS is unavailable (disabled, denied, or failed).
class LocationAccessMessages {
  LocationAccessMessages._();

  static void showFailureSnackBar(
    BuildContext context, {
    required String message,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: _suggestOpenSettings(message) ? 'Settings' : 'OK',
          onPressed: () {
            if (_suggestOpenSettings(message)) {
              Geolocator.openAppSettings();
            }
          },
        ),
      ),
    );
  }

  static bool _suggestOpenSettings(String message) {
    final m = message.toLowerCase();
    return m.contains('permission') ||
        m.contains('settings') ||
        m.contains('disabled');
  }

  static Future<void> openOsLocationSettings() =>
      Geolocator.openLocationSettings();
}
