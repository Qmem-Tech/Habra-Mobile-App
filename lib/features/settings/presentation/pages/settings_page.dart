import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habra_mobile_app/l10n/app_localizations.dart';
import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/localization/localization_cubit.dart' as loc;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/permission_list_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // Language Section
          ListTile(
            title: Text(l10n.language),
            subtitle: BlocBuilder<LocalizationCubit, loc.LocalizationState>(
              builder: (context, state) {
                return Text(_getLanguageName(state.locale.languageCode));
              },
            ),
            trailing: const Icon(Icons.language),
            onTap: () => _showLanguageDialog(context),
          ),
          // Permissions Section
          ListTile(
            title: const Text('Permissions'),
            subtitle: const Text('Manage location, camera, photos & more'),
            trailing: Icon(Icons.security, color: AppColors.brandSecondary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PermissionListPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final cubit = context.read<LocalizationCubit>();

    showDialog(
      context: context,
      builder: (context) => BlocBuilder<LocalizationCubit, loc.LocalizationState>(
        builder: (context, state) {
          return AlertDialog(
            title: const Text('Select Language'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: cubit.supportedLocales.map((locale) {
                return RadioListTile<Locale>(
                  title: Text(_getLanguageName(locale.languageCode)),
                  value: locale,
                  // ignore: deprecated_member_use - RadioGroup migration when stable
                  groupValue: state.locale,
                  // ignore: deprecated_member_use - RadioGroup migration when stable
                  onChanged: (value) {
                    if (value != null) {
                      cubit.setLocale(value);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
