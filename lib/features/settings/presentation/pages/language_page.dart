import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/localization/localization_cubit.dart' as loc;
import '../../../../features/splash/presentation/pages/splash_page.dart';

/// Language selection with card-style options and Save & Restart.
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  static const List<LocaleOption> _options = [
    LocaleOption(Locale('en'), 'English'),
    LocaleOption(Locale('ar'), 'Arabic'),
    LocaleOption(Locale('fr'), 'French'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocBuilder<LocalizationCubit, loc.LocalizationState>(
        builder: (context, state) {
          final currentCode = state.locale.languageCode;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppResources.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose your preferred language',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppResources.spacingS),
                Text(
                  'Select the language you are most comfortable with.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.brandPrimary,
                      ),
                ),
                const SizedBox(height: AppResources.spacingXL),
                ..._options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: AppResources.spacingM),
                    child: _LanguageCard(
                      label: option.label,
                      locale: option.locale,
                      isSelected: currentCode == option.locale.languageCode,
                      onTap: () async {
                      await context.read<LocalizationCubit>().setLocale(option.locale);
                    },
                    ),
                  ),
                ),
                const SizedBox(height: AppResources.spacingM),
                Container(
                  padding: const EdgeInsets.all(AppResources.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppResources.radiusM),
                    border: Border.all(
                      color: AppColors.brandPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.brandPrimary,
                        size: 24,
                      ),
                      const SizedBox(width: AppResources.spacingM),
                      Expanded(
                        child: Text(
                          'Changing the language will restart the application to apply the new settings.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppResources.spacingXL),
                AppButton(
                  text: 'Save & Restart',
                  onPressed: () => _saveAndRestart(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveAndRestart(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashPage()),
      (route) => false,
    );
  }
}

class LocaleOption {
  final Locale locale;
  final String label;

  const LocaleOption(this.locale, this.label);
}

class _LanguageCard extends StatelessWidget {
  final String label;
  final Locale locale;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.label,
    required this.locale,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingM,
            vertical: AppResources.spacingL,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandPrimary
                : AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppResources.radiusL),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandPrimary
                  : AppColors.backgroundGrey,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isSelected
                            ? AppColors.textOnPrimary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
