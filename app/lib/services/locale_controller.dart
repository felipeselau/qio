import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  static const prefsKey = 'locale';

  static const supportedCodes = ['pt', 'en', 'es'];

  Locale? _locale;

  Locale? get locale => _locale;

  static Locale? parse(String? raw) =>
      supportedCodes.contains(raw) ? Locale(raw!) : null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = parse(prefs.getString(prefsKey));
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale?.languageCode == _locale?.languageCode) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(prefsKey);
    } else {
      await prefs.setString(prefsKey, locale.languageCode);
    }
  }
}
