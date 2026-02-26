import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:askme_humg/l10n/app_localizations.dart';
import 'package:askme_humg/config/languages.dart';
import 'package:askme_humg/config/bootstrap.dart';
import 'package:askme_humg/app/modules/home/screens/home_screen.dart';
import 'package:askme_humg/app/core/values/app_fontsize.dart';

Future<void> main() async {
  await AppBootstrap.init();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final LocaleController _localeController = LocaleController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Inter',
        textTheme: AppTextTheme.applyTo(Theme.of(context).textTheme),
      ),
      locale: _localeController.locale, // default + runtime switch
      localeResolutionCallback: (deviceLocale, supported) {
        if (deviceLocale == null) return defaultLocale;
        for (final l in supported) {
          if (l.languageCode == deviceLocale.languageCode) return l;
        }
        return defaultLocale;
      },
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: localizationDelegateConst,
      supportedLocales: supportedLanguages,
      home: HomePage(
        currentLocale: _localeController.locale,
        onLocaleChanged: (l) => setState(() => _localeController.setLocale(l)),
      ),
    );
  }

  // Constant delegate cho localizations
  static const localizationDelegateConst = [
    AppLocalizations.delegate, // Thêm delegate của app
    GlobalMaterialLocalizations.delegate, // Thêm delegate của material
    GlobalCupertinoLocalizations.delegate, // Thêm delegate của cupertino
    GlobalWidgetsLocalizations.delegate, // Thêm delegate của widgets
  ];
}
