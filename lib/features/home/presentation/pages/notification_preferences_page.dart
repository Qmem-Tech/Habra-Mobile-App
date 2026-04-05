import 'package:flutter/material.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../injection/injection_container.dart' as di;

/// Local notification toggles for owners until a Supabase-backed prefs API exists.
class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key, required this.userId});

  final String userId;

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  static String _pushKey(String userId) =>
      '${StorageKeys.ownerPushNotificationsEnabled}_$userId';

  final LocalStorage _storage = di.sl<LocalStorage>();
  bool _pushEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stored = await _storage.getBool(_pushKey(widget.userId));
    if (!mounted) return;
    setState(() {
      _pushEnabled = stored ?? true;
      _loading = false;
    });
  }

  Future<void> _onPushChanged(bool value) async {
    setState(() => _pushEnabled = value);
    await _storage.setBool(_pushKey(widget.userId), value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          'Notification preferences',
          style: AppFonts.mediumTitle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppResources.spacingL),
              children: [
                Text(
                  'Choose how we reach you about your listings. More granular '
                  'controls will sync to your account when available.',
                  style: AppFonts.bodySmall(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppResources.spacingL),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Push notifications',
                    style: AppFonts.body(color: AppColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Alerts for reviews, jobs, and listing activity',
                    style: AppFonts.bodySmall(color: AppColors.textSecondary),
                  ),
                  value: _pushEnabled,
                  activeThumbColor: AppColors.brandPrimary,
                  onChanged: _onPushChanged,
                ),
              ],
            ),
    );
  }
}
