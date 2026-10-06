import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/theme_controller.dart';
import 'package:qio_app/theme/qio_colors.dart';
import 'package:qio_app/theme/qio_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => QioColors.apply(Brightness.light));

  test('parse falls back to system', () {
    expect(ThemeController.parse(null), ThemeMode.system);
    expect(ThemeController.parse('dark'), ThemeMode.dark);
    expect(ThemeController.parse('light'), ThemeMode.light);
    expect(ThemeController.parse('x'), ThemeMode.system);
  });

  test('setMode persists and load restores', () async {
    final c = ThemeController.instance;
    await c.setMode(ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ThemeController.prefsKey), 'dark');
    await c.setMode(ThemeMode.system);
    SharedPreferences.setMockInitialValues({ThemeController.prefsKey: 'dark'});
    await c.load();
    expect(c.mode, ThemeMode.dark);
    expect(c.resolve(Brightness.light), Brightness.dark);
  });

  test('system mode follows platform brightness', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ThemeController.instance;
    await c.load();
    expect(c.resolve(Brightness.dark), Brightness.dark);
    expect(c.resolve(Brightness.light), Brightness.light);
  });

  test('dark theme swaps surfaces and text', () {
    final light = QioTheme.forBrightness(Brightness.light);
    final lightSurface = light.colorScheme.surface;
    final lightText = QioColors.textPrimary;
    final dark = QioTheme.forBrightness(Brightness.dark);
    expect(dark.brightness, Brightness.dark);
    expect(dark.colorScheme.surface, isNot(lightSurface));
    expect(QioColors.textPrimary, isNot(lightText));
    expect(QioColors.isDark, isTrue);
  });
}
