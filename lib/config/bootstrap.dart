import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:askme_humg/config/di.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> init() async {
    // Global error presentation (extend to Sentry/Crashlytics if needed)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };

    // Load environment variables from .env if present
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Ignore missing .env in CI/production or when using dart-define
    }

    // Dependencies
    await setupDependencies();
  }
}
