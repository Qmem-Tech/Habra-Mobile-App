import 'package:flutter/material.dart';
import 'habra_circular_loader.dart';

/// Helper class to show/hide full-screen loader
///
/// Usage:
/// ```dart
/// // Show loader
/// LoaderHelper.show(context, message: 'Loading...');
///
/// // Hide loader
/// LoaderHelper.hide(context);
/// ```
class LoaderHelper {
  /// Show full-screen loader
  static void show(
    BuildContext context, {
    String? message,
    Color? backgroundColor,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => HabraCircularLoader(
        fullScreen: true,
        message: message,
        backgroundColor: backgroundColor ?? Colors.transparent,
      ),
    );
  }

  /// Hide full-screen loader. Returns a Future so callers can await before showing another overlay.
  static Future<void> hide(BuildContext context) async {
    if (!context.mounted) return;
    await Navigator.of(context, rootNavigator: true).maybePop();
  }
}
