import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/widgets/qio_button.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('renders label and fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(QioButton(label: 'Entrar', onPressed: () => tapped = true)),
    );

    expect(find.text('Entrar'), findsOneWidget);
    await tester.tap(find.text('Entrar'));
    expect(tapped, isTrue);
  });

  testWidgets('does not fire when onPressed is null', (tester) async {
    await tester.pumpWidget(wrap(const QioButton(label: 'Desabilitado')));

    await tester.tap(find.text('Desabilitado'));
    await tester.pump();
    expect(find.text('Desabilitado'), findsOneWidget);
  });

  testWidgets('shows spinner and blocks taps while loading', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        QioButton(label: 'Salvando', isLoading: true, onPressed: () => tapped = true),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Salvando'), findsNothing);
    await tester.tap(find.byType(CircularProgressIndicator));
    expect(tapped, isFalse);
  });

  testWidgets('renders icon when provided', (tester) async {
    await tester.pumpWidget(
      wrap(
        const QioButton(
          label: 'Compartilhar',
          icon: Icons.share,
        ),
      ),
    );

    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.text('Compartilhar'), findsOneWidget);
  });

  testWidgets('isFullWidth stretches to available width', (tester) async {
    await tester.pumpWidget(
      wrap(const QioButton(key: Key('btn'), label: 'Largo', isFullWidth: true)),
    );

    final buttonWidth = tester.getSize(find.byKey(const Key('btn'))).width;
    final scaffoldWidth = tester.getSize(find.byType(Scaffold)).width;
    expect(buttonWidth, scaffoldWidth);
  });
}
