import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/widgets/queue_panel/anonymize_phone_tile.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('toggling the switch saves anonymizePhone', (tester) async {
    final queues = FakeQueueService();
    await pumpApp(
      tester,
      Scaffold(
        body: AnonymizePhoneTile(queueId: 'q1', value: false, queues: queues),
      ),
    );
    expect(find.text('Não guardar telefone no histórico'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(queues.calls, contains('anonymize:q1:true'));
  });

  testWidgets('reflects the current value', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: AnonymizePhoneTile(
          queueId: 'q1',
          value: true,
          queues: FakeQueueService(),
        ),
      ),
    );
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  test('Queue.fromDoc reads anonymizePhone and retentionDays', () {
    final q = Queue.fromDoc('q1', {
      'ownerId': 'u',
      'name': 'x',
      'anonymizePhone': true,
      'retentionDays': 90,
    });
    expect(q.anonymizePhone, isTrue);
    expect(q.retentionDays, 90);
    final d = Queue.fromDoc('q2', {'ownerId': 'u', 'name': 'x'});
    expect(d.anonymizePhone, isFalse);
    expect(d.retentionDays, isNull);
  });
}
