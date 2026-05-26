import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_version_service.dart';
import '../theme/app_colors.dart';

bool _forceUpdateDialogVisible = false;

/// Whether the blocking update dialog is currently on screen.
bool get isForceUpdateDialogVisible => _forceUpdateDialogVisible;

/// Blocking update prompt. Not dismissible; only action opens the store.
Future<void> showForceUpdateDialog(
  BuildContext context,
  AppVersionStatus status,
) {
  if (_forceUpdateDialogVisible) return Future.value();
  _forceUpdateDialogVisible = true;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Update required',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            status.message ??
                'A newer version of Habra is required to continue. '
                    'Please update to keep using the app.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _openStore(status.storeUrl),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Update'),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actionsAlignment: MainAxisAlignment.center,
        ),
      );
    },
  ).whenComplete(() {
    _forceUpdateDialogVisible = false;
  });
}

Future<void> _openStore(String? storeUrl) async {
  final url = storeUrl?.trim();
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
