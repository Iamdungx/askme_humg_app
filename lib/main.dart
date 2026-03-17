import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/settings/presentation/settings_providers.dart';
import 'package:askme_humg/app/modules/settings/data/notification_service.dart';
import 'package:askme_humg/l10n/app_localizations.dart';
import 'package:askme_humg/config/languages.dart';
import 'package:askme_humg/config/bootstrap.dart';
import 'package:askme_humg/config/router.dart';
import 'package:askme_humg/app/core/values/app_theme.dart';
import 'package:askme_humg/app/core/providers/theme_provider.dart';
import 'package:askme_humg/config/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bắt Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}\n${details.stack}');
  };

  // Bắt async errors ngoài Flutter zone
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error\n$stack');
    return false;
  };

  await AppBootstrap.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          AppBootstrap.sharedPreferences,
        ),
      ],
      child: const MainApp(),
    ),
  );
}

final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(appRouterProvider);

    // Ensure OneSignal is initialized once (via provider-backed singleton).
    ref.watch(notificationBootstrapProvider);

    // Global foreground UX + tap navigation.
    ref.listen<AsyncValue<ForegroundNotificationEvent>>(
      notificationForegroundsProvider,
      (_, next) {
      final event = next.asData?.value;
      if (event == null) return;
      final msg = [event.title, event.body]
          .where((s) => s.trim().isNotEmpty)
          .join(' — ');
      if (msg.isEmpty) return;
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(msg)),
      );
    },
    );
    ref.listen<AsyncValue<Map<String, dynamic>>>(
      notificationTapsProvider,
      (_, next) {
      final data = next.asData?.value;
      if (data == null) return;
      final type = (data['type'] as String?)?.trim();
      if (type == 'new_question' || type == 'new_comment') {
        router.go(AppRoutes.inbox);
      }
    },
    );

    // OneSignal: login khi có user, logout khi đăng xuất
    ref.listen(authStateProvider, (prev, next) {
      final svc = ref.read(notificationServiceProvider);
      if (!svc.isAvailable) return;
      final user = next.asData?.value;
      if (user != null) {
        svc.login(user.uid);
      } else {
        svc.logout();
      }
    });

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp.router(
        scaffoldMessengerKey: _scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        locale: locale,
        routerConfig: router,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: supportedLanguages,
      ),
    );
  }
}
