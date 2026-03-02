import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/config/languages.dart';

part 'theme_provider.g.dart';

const _kLocaleKey = 'locale';

/// Persists and exposes the current [Locale].
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_kLocaleKey);
    if (stored != null) {
      final match = supportedLanguages.where((l) => l.languageCode == stored);
      if (match.isNotEmpty) return match.first;
    }
    return defaultLocale;
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLanguages.contains(locale)) return;
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }
}

const _kThemeModeKey = 'theme_mode';

/// Provides a pre-loaded [SharedPreferences] instance.
/// Initialized once in [AppBootstrap.init] via [ProviderContainer.read].
@riverpod
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError(
    'Override sharedPreferencesProvider in ProviderScope',
  );
}

/// Persists and exposes the current [ThemeMode].
///
/// Read theme in widgets:
/// ```dart
/// final mode = ref.watch(themeModeProvider);
/// ```
///
/// Toggle in a button callback:
/// ```dart
/// ref.read(themeModeProvider.notifier).toggle();
/// ```
///
/// Set explicitly:
/// ```dart
/// ref.read(themeModeProvider.notifier).setMode(ThemeMode.light);
/// ```
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_kThemeModeKey);
    final mode = _fromString(stored);
    if (mode == ThemeMode.system) {
      Future.microtask(() async {
        try {
          await prefs.setString(_kThemeModeKey, ThemeMode.light.name);
        } catch (e, s) {
          logger.e(
            'Failed to migrate theme pref to light',
            error: e,
            stackTrace: s,
          );
        }
      });
      return ThemeMode.light;
    }
    return mode;
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kThemeModeKey, mode.name);
  }

  static ThemeMode _fromString(String? value) {
    if (value == 'light') return ThemeMode.light;
    if (value == 'dark') return ThemeMode.dark;
    return ThemeMode.system; // sentinel: "chưa set hoặc giá trị lạ"
  }
}
