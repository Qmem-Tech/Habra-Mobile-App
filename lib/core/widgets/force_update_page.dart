import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../resources/app_assets.dart';
import '../services/app_version_service.dart';
import '../theme/app_colors.dart';

/// Blocking screen shown when the installed app is below the minimum supported
/// version. The user cannot pop back; the only action is to open the store.
class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key, required this.status});

  final AppVersionStatus status;

  @override
  Widget build(BuildContext context) {
    final storeUrl = status.storeUrl;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppAssets.appLogo,
                  width: 96,
                  height: 96,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.system_update_rounded,
                    size: 96,
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Update Habra',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  status.message ??
                      'A newer version of Habra is required to continue. '
                          'Please update to keep using the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Update Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: storeUrl == null || storeUrl.isEmpty
                        ? null
                        : () async {
                            final uri = Uri.tryParse(storeUrl);
                            if (uri == null) return;
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          },
                  ),
                ),
                if (status.current != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'You\'re on ${status.current}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
