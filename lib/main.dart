import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:askme_humg/l10n/app_localizations.dart';
import 'package:askme_humg/config/languages.dart';
import 'package:askme_humg/config/bootstrap.dart';
import 'package:askme_humg/config/router.dart';
import 'package:askme_humg/app/core/values/app_theme.dart';
import 'package:askme_humg/app/core/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.init();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(AppBootstrap.sharedPreferences),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: supportedLanguages,
      localeResolutionCallback: (deviceLocale, supported) {
        if (deviceLocale == null) return defaultLocale;
        for (final l in supported) {
          if (l.languageCode == deviceLocale.languageCode) return l;
        }
        return defaultLocale;
      },
    );
  }
}
