import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../storage/local_storage.dart';
import '../constants/storage_keys.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final LocalStorage localStorage;

  ThemeCubit({required this.localStorage}) : super(const ThemeState(themeMode: AppThemeMode.system)) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final savedTheme = await localStorage.getString(StorageKeys.themeMode);
    if (savedTheme != null) {
      final themeMode = AppThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => AppThemeMode.system,
      );
      emit(state.copyWith(themeMode: themeMode));
    }
  }

  Future<void> setTheme(AppThemeMode themeMode) async {
    await localStorage.setString(StorageKeys.themeMode, themeMode.toString());
    emit(state.copyWith(themeMode: themeMode));
  }

  ThemeMode get themeMode {
    switch (state.themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
