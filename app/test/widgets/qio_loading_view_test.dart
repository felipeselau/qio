import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/widgets/qio_loading_view.dart';

void main() {
  testWidgets('shows the branded symbol on the brand color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: QioLoadingView())),
    );
    expect(find.bySemanticsLabel('Qio'), findsOneWidget);
    final box = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(QioLoadingView),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(box.color, QioLoadingView.background);
    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('does not animate when animations are disabled', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: Scaffold(body: QioLoadingView())),
      ),
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
