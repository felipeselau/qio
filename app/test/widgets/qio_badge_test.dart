import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/theme/qio_colors.dart';
import 'package:qio_app/widgets/qio_badge.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('renders label', (tester) async {
    await tester.pumpWidget(
      wrap(const QioBadge(label: 'Aberta', status: QioBadgeStatus.open)),
    );
    expect(find.text('Aberta'), findsOneWidget);
  });

  testWidgets('open badge uses success color', (tester) async {
    await tester.pumpWidget(
      wrap(const QioBadge(label: 'Aberta', status: QioBadgeStatus.open)),
    );

    final text = tester.widget<Text>(find.text('Aberta'));
    expect(text.style?.color, QioColors.statusOpen);
  });

  testWidgets('paused badge uses warning color', (tester) async {
    await tester.pumpWidget(
      wrap(const QioBadge(label: 'Pausada', status: QioBadgeStatus.paused)),
    );

    final text = tester.widget<Text>(find.text('Pausada'));
    expect(text.style?.color, QioColors.statusPaused);
  });

  testWidgets('closed badge uses error color', (tester) async {
    await tester.pumpWidget(
      wrap(const QioBadge(label: 'Fechada', status: QioBadgeStatus.closed)),
    );

    final text = tester.widget<Text>(find.text('Fechada'));
    expect(text.style?.color, QioColors.statusClosed);
  });
}
