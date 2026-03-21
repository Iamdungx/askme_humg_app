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
  static const resendApiKey = 'RESEND_API_KEY';
  static const resendFromEmail = 'RESEND_FROM_EMAIL';
  static const gmailUser = 'GMAIL_USER';
  static const gmailAppPassword = 'GMAIL_APP_PASSWORD';
  static const oneSignalAppId = 'ONESIGNAL_APP_ID';
  static const notifyWebhookUrl = 'NOTIFY_WEBHOOK_URL';
  static const appCheckProvider = 'APP_CHECK_PROVIDER';
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

  /// Resend API key for sending OTP emails (UC-1.3).
  static String get resendApiKey => _envOrEmpty(_EnvKeys.resendApiKey);

  /// Resend sender email address (must be verified on resend.com).
  static String get resendFromEmail =>
      _envOr(_EnvKeys.resendFromEmail, 'onboarding@resend.dev');

  /// Gmail SMTP — dùng khi chưa verify domain Resend.
  static String get gmailUser => _envOrEmpty(_EnvKeys.gmailUser);
  static String get gmailAppPassword => _envOrEmpty(_EnvKeys.gmailAppPassword);

  /// OneSignal App ID (Settings > Keys & IDs). Cần khi dùng push không Blaze.
  static String get oneSignalAppId => _envOrEmpty(_EnvKeys.oneSignalAppId);

  /// URL webhook gửi thông báo (Vercel/Netlify). Gọi sau khi tạo question/comment.
  static String get notifyWebhookUrl => _envOrEmpty(_EnvKeys.notifyWebhookUrl);

  /// App Check provider mode: auto | debug | release.
  /// - auto: release provider only when APP_ENV is release and build is release
  /// - debug: always use debug provider (for local/internal testing)
  /// - release: always use production provider
  static String get appCheckProvider {
    final raw = _envOrEmpty(_EnvKeys.appCheckProvider).trim().toLowerCase();
    if (raw == 'debug' || raw == 'release' || raw == 'auto') return raw;
    return 'auto';
  }

  /// Reads a boolean flag: "true" / "1" / "yes" → true (case-insensitive).
  static bool flag(String key, {bool defaultValue = false}) {
    final v = _envOrEmpty(key).toLowerCase();
    if (v.isEmpty) return defaultValue;
    return v == 'true' || v == '1' || v == 'yes';
  }
}
