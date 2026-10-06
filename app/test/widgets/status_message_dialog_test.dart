import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/widgets/queue_panel/queue_limit_tile.dart';
import 'package:qio_app/widgets/queue_panel/status_message_dialog.dart';

Widget host(Widget Function(BuildContext) button) => MaterialApp(
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Builder(builder: button)),
);

void main() {
  testWidgets('pause dialog returns the typed message', (tester) async {
    StatusChange? result;
    await tester.pumpWidget(
      host(
        (context) => TextButton(
          onPressed: () async => result = await showStatusMessageDialog(
            context,
            QueueStatus.paused,
          ),
          child: const Text('abrir'),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Pausar a fila'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Volto logo');
    await tester.tap(find.text('Pausar'));
    await tester.pumpAndSettle();
    expect(result?.message, 'Volto logo');
    expect(result?.resumeAt, isNull);
  });

  testWidgets('suggestion chips fill the field and cancel returns null', (
    tester,
  ) async {
    StatusChange? result = const StatusChange(message: 'x');
    await tester.pumpWidget(
      host(
        (context) => TextButton(
          onPressed: () async => result = await showStatusMessageDialog(
            context,
            QueueStatus.paused,
          ),
          child: const Text('abrir'),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volto em 10 minutos'));
    await tester.pump();
    expect(
      find.widgetWithText(TextField, 'Volto em 10 minutos'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('close dialog has no return time', (tester) async {
    await tester.pumpWidget(
      host(
        (context) => TextButton(
          onPressed: () => showStatusMessageDialog(context, QueueStatus.closed),
          child: const Text('abrir'),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Fechar a fila'), findsOneWidget);
    expect(find.text('Previsão de retorno'), findsNothing);
  });

  test('resumeTimeToday rolls to tomorrow when the time already passed', () {
    final now = DateTime(2026, 10, 6, 15, 0);
    expect(
      resumeTimeToday(const TimeOfDay(hour: 16, minute: 30), now),
      DateTime(2026, 10, 6, 16, 30),
    );
    expect(
      resumeTimeToday(const TimeOfDay(hour: 9, minute: 0), now),
      DateTime(2026, 10, 7, 9, 0),
    );
  });

  test('queue parses limit, message and return time', () {
    final q = Queue.fromDoc('q', {
      'ownerId': 'o',
      'name': 'F',
      'maxWaiting': 30,
      'statusMessage': 'Intervalo',
      'resumeAt': Timestamp.fromDate(DateTime(2026, 10, 6, 16)),
    });
    expect(q.maxWaiting, 30);
    expect(q.hasLimit, isTrue);
    expect(q.statusMessage, 'Intervalo');
    expect(q.resumeAt, DateTime(2026, 10, 6, 16));
    final plain = Queue.fromDoc('q', {'ownerId': 'o', 'name': 'F'});
    expect(plain.maxWaiting, 0);
    expect(plain.hasLimit, isFalse);
    expect(plain.statusMessage, isNull);
  });

  testWidgets('validateMaxWaiting accepts empty and 1..1000 only', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      host((context) {
        l10n = AppLocalizations.of(context);
        return const SizedBox();
      }),
    );
    expect(validateMaxWaiting('', l10n), isNull);
    expect(validateMaxWaiting(null, l10n), isNull);
    expect(validateMaxWaiting('30', l10n), isNull);
    expect(validateMaxWaiting('1000', l10n), isNull);
    for (final bad in ['0', '1001', '-3', 'abc', '2.5']) {
      expect(validateMaxWaiting(bad, l10n), isNotNull, reason: bad);
    }
  });
}
