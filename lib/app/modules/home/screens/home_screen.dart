import 'package:flutter/material.dart';
import 'package:askme_humg/l10n/app_localizations.dart';
import 'package:askme_humg/app/global_widgets/language_switch.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).appTitle)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Text(AppLocalizations.of(context).hello)),
          const SizedBox(height: 16),
          LanguageSwitch(
            currentLocale: currentLocale,
            onChanged: onLocaleChanged,
          ),
        ],
      ),
    );
  }
}
