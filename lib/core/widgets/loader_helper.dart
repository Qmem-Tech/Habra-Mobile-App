import 'package:flutter/material.dart';
import 'full_screen_loader.dart';

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
      builder: (context) => FullScreenLoader(
        message: message,
        backgroundColor: backgroundColor ?? Colors.transparent,
      ),
    );
  }

  /// Hide full-screen loader
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
