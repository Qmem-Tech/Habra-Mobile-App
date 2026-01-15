import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habra_mobile_app/l10n/app_localizations.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/theme_state.dart';
import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/localization/localization_cubit.dart' as loc;

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
          // Theme Section
          ListTile(
            title: Text(l10n.theme),
            subtitle: BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                return Text(_getThemeModeText(state.themeMode, l10n));
              },
            ),
            trailing: const Icon(Icons.brightness_6),
            onTap: () => _showThemeDialog(context, l10n),
          ),

          const Divider(),

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
        ],
      ),
    );
  }

  String _getThemeModeText(AppThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case AppThemeMode.light:
        return l10n.lightMode;
      case AppThemeMode.dark:
        return l10n.darkMode;
      case AppThemeMode.system:
        return l10n.systemDefault;
    }
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

  void _showThemeDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return AlertDialog(
            title: Text(l10n.theme),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<AppThemeMode>(
                  title: Text(l10n.lightMode),
                  value: AppThemeMode.light,
                  groupValue: state.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<ThemeCubit>().setTheme(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<AppThemeMode>(
                  title: Text(l10n.darkMode),
                  value: AppThemeMode.dark,
                  groupValue: state.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<ThemeCubit>().setTheme(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<AppThemeMode>(
                  title: Text(l10n.systemDefault),
                  value: AppThemeMode.system,
                  groupValue: state.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<ThemeCubit>().setTheme(value);
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
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
                  groupValue: state.locale,
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
