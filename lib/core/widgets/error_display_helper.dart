import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_error_card.dart';

/// Centralized error display helper.
///
/// Shows a beautiful, dismissible error card that appears above dialogs and loaders.
/// Use this instead of SnackBar when errors might be hidden behind popups.
///
/// Usage:
/// ```dart
/// try {
///   await someOperation();
/// } catch (e) {
///   if (context.mounted) {
///     ErrorDisplayHelper.show(context, error: e);
///   }
/// }
/// ```
class ErrorDisplayHelper {
  ErrorDisplayHelper._();

  /// Show an error card overlay. Appears above dialogs, loaders, and other UI.
  ///
  /// [message] - Optional custom message. If not provided, [error] is converted to user-friendly text.
  /// [title] - Optional custom title. Default: "Something went wrong"
  /// [onRetry] - Optional callback when user taps "Try Again"
  static void show(
    BuildContext context, {
    Object? error,
    String? message,
    String? title,
    VoidCallback? onRetry,
  }) {
    final userMessage = message ?? _toUserFriendlyMessage(error);
    final userTitle = title ?? 'Something went wrong';
    final detailText = (error != null && kDebugMode) ? error.toString() : null;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      useRootNavigator: true,
      builder: (ctx) => AppErrorCard(
        title: userTitle,
        message: userMessage,
        detailText: detailText,
        onRetry: onRetry,
        onDismiss: () {},
      ),
    );
  }

  /// Convert raw error/exception to a user-friendly message.
  static String _toUserFriendlyMessage(Object? error) {
    if (error == null) return 'Please try again.';
    final str = error.toString().toLowerCase();

    // Connection / network
    if (str.contains('connection') ||
        str.contains('network') ||
        str.contains('socket') ||
        str.contains('timeout') ||
        str.contains('unreachable')) {
      return 'Check your internet connection and try again.';
    }

    // Storage / upload – check BEFORE auth; Supabase Storage RLS failures often return "unauthorized"
    // even when the user is signed in, so we prioritise storage messages for upload flows
    if (str.contains('upload') ||
        str.contains('storage') ||
        str.contains('permission') ||
        str.contains('bucket') ||
        str.contains('row-level security') ||
        str.contains('policy')) {
      return 'We couldn\'t upload your file. Check that the file is under 5MB and try again.';
    }

    // Auth (only when not a storage error)
    if (str.contains('unauthorized') ||
        str.contains('not authenticated') ||
        str.contains('session')) {
      return 'Please sign in again.';
    }

    // File size
    if (str.contains('5mb') || str.contains('size') || str.contains('too large')) {
      return 'File must be under 5MB. Try a smaller image.';
    }

    // Format
    if (str.contains('jpg') || str.contains('png') || str.contains('format')) {
      return 'Please use JPG, PNG, WebP, or GIF format.';
    }

    // Server / generic
    if (str.contains('exception') || str.contains('error') || str.contains('failed')) {
      return 'Something went wrong. Please try again.';
    }

    // Fallback: truncate long technical messages
    final raw = error.toString();
    if (raw.length > 120) {
      return 'Something went wrong. Please try again.';
    }
    // Keep short, readable messages as-is (e.g. "Business name is required")
    return raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^Error:\s*'), '');
  }
}
