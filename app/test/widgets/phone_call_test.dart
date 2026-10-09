import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_entry.dart';
import 'package:qio_app/services/phone_call.dart';
import 'package:qio_app/widgets/queue_panel/current_called_card.dart';
import 'package:qio_app/widgets/queue_panel/waiting_tile.dart';

import '../helpers/pump_app.dart';

QueueEntry entry({String? phone, EntryStatus status = EntryStatus.waiting}) =>
    QueueEntry(
      id: 'e1',
      ticket: 7,
      name: 'Ana',
      phone: phone,
      uid: 'c-1',
      status: status,
      joinedAt: DateTime(2025, 5, 20, 10),
    );

void main() {
  group('phoneToTelUri', () {
    test('mobile mask', () {
      expect(phoneToTelUri('(11) 99999-9999').toString(), 'tel:11999999999');
    });

    test('landline mask', () {
      expect(phoneToTelUri('(11) 3333-4444').toString(), 'tel:1133334444');
    });

    test('empty, null and invalid', () {
      expect(phoneToTelUri(null), isNull);
      expect(phoneToTelUri(''), isNull);
      expect(phoneToTelUri('   '), isNull);
      expect(phoneToTelUri('123'), isNull);
      expect(phoneToTelUri('abc'), isNull);
      expect(phoneToTelUri('(11) 99999-99999'), isNull);
    });
  });

  group('WaitingTile', () {
    testWidgets('without phone shows no call button', (tester) async {
      await pumpApp(tester, Scaffold(body: WaitingTile(entry: entry())));
      expect(find.byIcon(Icons.phone_outlined), findsNothing);
    });

    testWidgets('with phone shows number and launches tel', (tester) async {
      final calls = <Uri>[];
      await pumpApp(
        tester,
        Scaffold(
          body: WaitingTile(
            entry: entry(phone: '(11) 99999-9999'),
            launcher: (u) async {
              calls.add(u);
              return true;
            },
          ),
        ),
      );
      expect(find.text('(11) 99999-9999'), findsOneWidget);
      expect(find.byTooltip('Ligar para Ana'), findsOneWidget);
      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await tester.tap(find.byIcon(Icons.phone_outlined));
      await tester.pump();
      expect(calls.single.toString(), 'tel:11999999999');
      expect(find.text('Não foi possível abrir o discador'), findsNothing);
    });

    testWidgets('launch failure shows snackbar', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: WaitingTile(
            entry: entry(phone: '(11) 99999-9999'),
            launcher: (_) async => false,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.phone_outlined));
      await tester.pump();
      expect(find.text('Não foi possível abrir o discador'), findsOneWidget);
    });

    testWidgets('launch exception shows snackbar', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: WaitingTile(
            entry: entry(phone: '(11) 99999-9999'),
            launcher: (_) async => throw Exception('x'),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.phone_outlined));
      await tester.pump();
      expect(find.text('Não foi possível abrir o discador'), findsOneWidget);
    });
  });

  group('CurrentCalledCard', () {
    testWidgets('without phone has no call button', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: CurrentCalledCard(
            entry: entry(status: EntryStatus.called),
            queueId: 'q1',
          ),
        ),
      );
      expect(find.byIcon(Icons.phone_outlined), findsNothing);
    });

    testWidgets('with phone launches tel', (tester) async {
      final calls = <Uri>[];
      await pumpApp(
        tester,
        Scaffold(
          body: CurrentCalledCard(
            entry: entry(phone: '(11) 99999-9999', status: EntryStatus.called),
            queueId: 'q1',
            launcher: (u) async {
              calls.add(u);
              return true;
            },
          ),
        ),
      );
      expect(find.text('(11) 99999-9999'), findsOneWidget);
      await tester.tap(find.byTooltip('Ligar para Ana'));
      await tester.pump();
      expect(calls.single.toString(), 'tel:11999999999');
    });
  });
}
