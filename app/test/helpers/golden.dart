import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

const double goldenTolerance = 0.005;

class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, {this.tolerance = goldenTolerance});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

void installTolerantGoldenComparator() {
  final current = goldenFileComparator;
  if (current is LocalFileComparator && current is! TolerantGoldenComparator) {
    goldenFileComparator = TolerantGoldenComparator(
      current.basedir.resolve('golden_placeholder_test.dart'),
    );
  }
}

Future<void> goldenApp(
  WidgetTester tester,
  Widget child,
  String name, {
  Locale locale = const Locale('pt'),
  ThemeMode themeMode = ThemeMode.light,
  Size size = const Size(390, 844),
  Duration settle = const Duration(milliseconds: 600),
}) async {
  await pumpApp(
    tester,
    child,
    locale: locale,
    themeMode: themeMode,
    size: size,
  );
  await tester.pump(settle);
  await tester.pump(settle);
  if (!Platform.isLinux) return;
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../goldens/$name.png'),
  );
}
