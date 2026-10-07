import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/theme/qio_theme.dart';

Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('pt'),
  ThemeMode themeMode = ThemeMode.light,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final theme = themeMode == ThemeMode.dark ? QioTheme.dark : QioTheme.light;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme,
      darkTheme: theme,
      themeMode: themeMode,
      home: child,
    ),
  );
}
