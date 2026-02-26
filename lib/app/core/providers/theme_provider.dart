import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

const _kThemeModeKey = 'theme_mode';

/// Provides a pre-loaded [SharedPreferences] instance.
/// Initialized once in [AppBootstrap.init] via [ProviderContainer.read].
@riverpod
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('Override sharedPreferencesProvider in ProviderScope');
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
      scheduleMicrotask(
        () => prefs.setString(_kThemeModeKey, ThemeMode.dark.name),
      );
      return ThemeMode.dark;
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
