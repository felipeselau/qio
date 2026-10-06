import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('parse accepts supported codes and falls back to system', () {
    expect(LocaleController.parse(null), isNull);
    expect(LocaleController.parse('x'), isNull);
    expect(LocaleController.parse('pt'), const Locale('pt'));
    expect(LocaleController.parse('en'), const Locale('en'));
    expect(LocaleController.parse('es'), const Locale('es'));
  });

  test('setLocale persists and load restores', () async {
    final c = LocaleController.instance;
    await c.setLocale(const Locale('es'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LocaleController.prefsKey), 'es');
    await c.setLocale(null);
    expect(prefs.getString(LocaleController.prefsKey), isNull);
    SharedPreferences.setMockInitialValues({LocaleController.prefsKey: 'en'});
    await c.load();
    expect(c.locale, const Locale('en'));
  });

  test('setLocale notifies listeners only on change', () async {
    final c = LocaleController.instance;
    await c.setLocale(null);
    var calls = 0;
    void listener() => calls++;
    c.addListener(listener);
    await c.setLocale(null);
    await c.setLocale(const Locale('pt'));
    await c.setLocale(const Locale('pt'));
    c.removeListener(listener);
    await c.setLocale(null);
    expect(calls, 1);
  });
}
