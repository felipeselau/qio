import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/expiry_config.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/widgets/queue_panel/expiry_tile.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('disabled shows only the master switch and saves defaults', (
    tester,
  ) async {
    final queues = FakeQueueService();
    await pumpApp(
      tester,
      Scaffold(
        body: ExpiryTile(queueId: 'q1', config: null, queues: queues),
      ),
    );
    expect(find.text('Expirar entradas esquecidas'), findsOneWidget);
    expect(find.byKey(const ValueKey('expiry-hours')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('expiry-enabled')));
    await tester.pump();
    expect(queues.calls, contains('expiry:q1:true:12:false:false'));
  });

  testWidgets('enabled shows hours and both options', (tester) async {
    final queues = FakeQueueService();
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ExpiryTile(
            queueId: 'q1',
            config: const ExpiryConfig(enabled: true, hours: 24),
            queues: queues,
          ),
        ),
      ),
    );
    expect(find.text('Expirar após 24 h'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('expiry-clear')));
    await tester.pump();
    expect(queues.calls, contains('expiry:q1:true:24:true:false'));
    await tester.tap(find.byKey(const ValueKey('expiry-reset')));
    await tester.pump();
    expect(queues.calls, contains('expiry:q1:true:24:false:true'));
  });

  testWidgets('shows an hour outside the preset list', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: SingleChildScrollView(
          child: ExpiryTile(
            queueId: 'q1',
            config: ExpiryConfig(enabled: true, hours: 5),
          ),
        ),
      ),
    );
    expect(find.text('Expirar após 5 h'), findsOneWidget);
  });

  test('fromMap tolerates wrong types', () {
    final c = ExpiryConfig.fromMap({'enabled': true, 'hours': '6'})!;
    expect(c.hours, 12);
    expect(ExpiryConfig.fromMap('x'), isNull);
  });

  test('Queue.fromDoc reads expiry and clamps invalid hours', () {
    final q = Queue.fromDoc('q1', {
      'ownerId': 'u',
      'name': 'x',
      'expiry': {'enabled': true, 'hours': 99, 'clearOnClose': true},
    });
    expect(q.expiry!.enabled, isTrue);
    expect(q.expiry!.hours, 12);
    expect(q.expiry!.clearOnClose, isTrue);
    expect(q.expiry!.resetTicketDaily, isFalse);
    expect(Queue.fromDoc('q2', {'ownerId': 'u', 'name': 'x'}).expiry, isNull);
  });
}
