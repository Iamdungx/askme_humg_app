// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnv { debug, stg, release }

extension AppEnvX on AppEnv {
  String get label => describeEnum(this);

  String get defaultBaseUrl {
    switch (this) {
      case AppEnv.debug:
        return 'https://api-dev.example.com';
      case AppEnv.stg:
        return 'https://api-stg.example.com';
      case AppEnv.release:
        return 'https://api.example.com';
    }
  }
}

class _EnvKeys {
  static const appEnv = 'APP_ENV';
  static const apiBaseUrl = 'API_BASE_URL';
}

class EnvReader {
  // Low-level getters (prefer .env if loaded, else dart-define)
  static String _envOrEmpty(String key) {
    final fromDotEnv = dotenv.maybeGet(key);
    if (fromDotEnv != null) return fromDotEnv;
    return String.fromEnvironment(key, defaultValue: '');
  }

  static String _envOr(String key, String def) {
    final fromDotEnv = dotenv.maybeGet(key);
    if (fromDotEnv != null && fromDotEnv.isNotEmpty) return fromDotEnv;
    return String.fromEnvironment(key, defaultValue: def);
  }

  // Environment selection
  static AppEnv get appEnv {
    final value = _envOr(_EnvKeys.appEnv, 'debug').toLowerCase();
    switch (value) {
      case 'stg':
      case 'staging':
        return AppEnv.stg;
      case 'release':
      case 'prod':
      case 'production':
        return AppEnv.release;
      case 'debug':
      default:
        return AppEnv.debug;
    }
  }

  static bool get isDebug => appEnv == AppEnv.debug;
  static bool get isStg => appEnv == AppEnv.stg;
  static bool get isRelease => appEnv == AppEnv.release;

  static String get appEnvLabel => appEnv.label;

  // API base URL with optional override
  static String get apiBaseUrl {
    final override = _envOrEmpty(_EnvKeys.apiBaseUrl);
    if (override.isNotEmpty) return override;
    return appEnv.defaultBaseUrl;
  }

  // Generic boolean flag reader: true/1/yes (case-insensitive) => true
  static bool flag(String key, {bool defaultValue = false}) {
    final v = _envOrEmpty(key).toLowerCase();
    if (v.isEmpty) return defaultValue;
    return v == 'true' || v == '1' || v == 'yes';
  }
}
