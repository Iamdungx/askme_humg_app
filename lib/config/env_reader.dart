import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnv { debug, stg, release }

extension AppEnvX on AppEnv {
  /// Dart 3: enum.name replaces the deprecated describeEnum()
  String get label => name;

  String get defaultBaseUrl => switch (this) {
    AppEnv.debug => 'https://api-dev.example.com',
    AppEnv.stg => 'https://api-stg.example.com',
    AppEnv.release => 'https://api.example.com',
  };
}

class _EnvKeys {
  static const appEnv = 'APP_ENV';
  static const apiBaseUrl = 'API_BASE_URL';
  static const googleServerClientId = 'GOOGLE_SERVER_CLIENT_ID';
}

class EnvReader {
  const EnvReader._();

  // Prefer .env if loaded, fall back to --dart-define
  static String _envOrEmpty(String key) =>
      dotenv.maybeGet(key) ?? String.fromEnvironment(key);

  static String _envOr(String key, String fallback) {
    final v = dotenv.maybeGet(key);
    return (v != null && v.isNotEmpty)
        ? v
        : String.fromEnvironment(key, defaultValue: fallback);
  }

  static AppEnv get appEnv {
    final value = _envOr(_EnvKeys.appEnv, 'debug').toLowerCase();
    return switch (value) {
      'stg' || 'staging' => AppEnv.stg,
      'release' || 'prod' || 'production' => AppEnv.release,
      _ => AppEnv.debug,
    };
  }

  static bool get isDebug => appEnv == AppEnv.debug;
  static bool get isStg => appEnv == AppEnv.stg;
  static bool get isRelease => appEnv == AppEnv.release;

  static String get appEnvLabel => appEnv.label;

  static String get apiBaseUrl {
    final override = _envOrEmpty(_EnvKeys.apiBaseUrl);
    return override.isNotEmpty ? override : appEnv.defaultBaseUrl;
  }

  /// Web Client ID for Google Sign-In v7 (required on Android).
  /// Get from: Firebase Console → Project Settings → General → Web app → Client ID
  static String get googleServerClientId =>
      _envOrEmpty(_EnvKeys.googleServerClientId);

  /// Reads a boolean flag: "true" / "1" / "yes" → true (case-insensitive).
  static bool flag(String key, {bool defaultValue = false}) {
    final v = _envOrEmpty(key).toLowerCase();
    if (v.isEmpty) return defaultValue;
    return v == 'true' || v == '1' || v == 'yes';
  }
}
