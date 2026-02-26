// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sharedPreferencesHash() => r'9e0dd89778d20a48e1cc8a307db27141dd223930';

/// Provides a pre-loaded [SharedPreferences] instance.
/// Initialized once in [AppBootstrap.init] via [ProviderContainer.read].
///
/// Copied from [sharedPreferences].
@ProviderFor(sharedPreferences)
final sharedPreferencesProvider =
    AutoDisposeProvider<SharedPreferences>.internal(
      sharedPreferences,
      name: r'sharedPreferencesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sharedPreferencesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SharedPreferencesRef = AutoDisposeProviderRef<SharedPreferences>;
String _$themeModeNotifierHash() => r'97d5e127878a97f0c39d913c11626a9a2e103941';

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
///
/// Copied from [ThemeModeNotifier].
@ProviderFor(ThemeModeNotifier)
final themeModeNotifierProvider =
    AutoDisposeNotifierProvider<ThemeModeNotifier, ThemeMode>.internal(
      ThemeModeNotifier.new,
      name: r'themeModeNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$themeModeNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ThemeModeNotifier = AutoDisposeNotifier<ThemeMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
