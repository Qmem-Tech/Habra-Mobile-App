import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../storage/local_storage.dart';
import '../constants/storage_keys.dart';

class LocalizationState extends Equatable {
  final Locale locale;

  const LocalizationState({required this.locale});

  LocalizationState copyWith({Locale? locale}) {
    return LocalizationState(
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object> get props => [locale];
}

class LocalizationCubit extends Cubit<LocalizationState> {
  final LocalStorage localStorage;

  LocalizationCubit({required this.localStorage})
      : super(const LocalizationState(locale: Locale('en'))) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final savedLocale = await localStorage.getString(StorageKeys.locale);
    if (savedLocale != null) {
      emit(state.copyWith(locale: Locale(savedLocale)));
    }
  }

  Future<void> setLocale(Locale locale) async {
    await localStorage.setString(StorageKeys.locale, locale.languageCode);
    emit(state.copyWith(locale: locale));
  }

  List<Locale> get supportedLocales => const [
        Locale('en'),
        Locale('ar'),
        Locale('fr'),
      ];
}
