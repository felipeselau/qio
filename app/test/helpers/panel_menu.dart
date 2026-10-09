import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapPanelAction(WidgetTester tester, String label) async {
  final direct = find.descendant(
    of: find.byType(AppBar),
    matching: find.byTooltip(label),
  );
  if (direct.evaluate().isNotEmpty) {
    await tester.tap(direct);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    return;
  }
  await tester.tap(
    find.descendant(
      of: find.byType(AppBar),
      matching: find.byTooltip('Mais ações'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}
