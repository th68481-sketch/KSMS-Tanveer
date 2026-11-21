import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSettings {
  const AppSettings({this.localeCode = 'en', this.themeMode = ThemeMode.system});
  final String localeCode;
  final ThemeMode themeMode;

  Locale get locale => Locale(localeCode);

  AppSettings copyWith({String? localeCode, ThemeMode? themeMode}) => AppSettings(
        localeCode: localeCode ?? this.localeCode,
        themeMode: themeMode ?? this.themeMode,
      );
}

/// Theme + language preferences, persisted locally.
class AppSettingsController extends Notifier<AppSettings> {
  static const _storage = FlutterSecureStorage();

  @override
  AppSettings build() {
    _restore();
    return const AppSettings();
  }

  Future<void> _restore() async {
    final locale = await _storage.read(key: 'ksms_locale');
    final mode = await _storage.read(key: 'ksms_theme');
    if (locale != null || mode != null) {
      state = state.copyWith(
        localeCode: locale,
        themeMode: switch (mode) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => null,
        },
      );
    }
  }

  Future<void> setLocale(String code) async {
    state = state.copyWith(localeCode: code);
    await _storage.write(key: 'ksms_locale', value: code);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _storage.write(
        key: 'ksms_theme',
        value: switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          _ => 'system',
        });
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(AppSettingsController.new);
