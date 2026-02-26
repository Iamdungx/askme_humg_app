import 'package:flutter/material.dart';

// Constant supported locales
const supportedLanguages = [Locale('en'), Locale('vi'), Locale('ja')];

// Default locale for the app
const defaultLocale = Locale('vi');

// Simple in-memory locale controller (for demo/runtime switching)
class LocaleController extends ChangeNotifier {
  LocaleController({Locale? initial}) : _locale = initial ?? defaultLocale;

  Locale _locale;
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!supportedLanguages.contains(locale)) return;
    _locale = locale;
    notifyListeners();
  }
}
