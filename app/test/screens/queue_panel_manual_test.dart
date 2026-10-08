import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_entry.dart';
import 'package:qio_app/models/queue_slot.dart';
import 'package:qio_app/screens/queue_panel_screen.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

const tall = Size(390, 2600);

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

QueuePanelScreen panel(
  FakeQueueService queues,
  FakeManualEntryService manual, {
  bool isOwner = true,
}) => QueuePanelScreen(
  queueId: 'q1',
  queueName: 'Padaria',
  isOwner: isOwner,
  queues: queues,
  operators: FakeOperatorService(),
  manualEntries: manual,
  groups: FakeGroupService(),
  showTour: false,
);

FakeQueueService service({List<QueueEntry> entries = const []}) =>
    FakeQueueService(
      queues: {'q1': fakeQueue('q1', name: 'Padaria')},
      entries: {'q1': entries},
    );

void main() {
  for (final isOwner in [true, false]) {
    testWidgets(
      '${isOwner ? 'dono' : 'operador'} adiciona pessoa pelo painel',
      (tester) async {
        final manual = FakeManualEntryService(ticket: 9);
        await pumpApp(
          tester,
          panel(service(), manual, isOwner: isOwner),
          size: tall,
        );
        await tick(tester);
        await tester.tap(find.byTooltip('Adicionar pessoa'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'Dona Maria');
        await tester.tap(find.text('Adicionar'));
        await tester.pumpAndSettle();
        expect(manual.calls.single['name'], 'Dona Maria');
        expect(manual.calls.single['queueId'], 'q1');
        expect(
          find.text('Dona Maria entrou na fila com a senha 9'),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('entry manual mostra o selo e o telefone', (tester) async {
    final queues = service(
      entries: [
        fakeEntry(
          'm1',
          1,
          name: 'Dona Maria',
          manual: true,
          phone: '(11) 3333-4444',
        ),
        fakeEntry('e2', 2, name: 'Bruno'),
      ],
    );
    await pumpApp(tester, panel(queues, FakeManualEntryService()), size: tall);
    await tick(tester);
    expect(find.text('Balcão'), findsOneWidget);
    expect(find.text('(11) 3333-4444'), findsOneWidget);
    expect(find.text('Dona Maria'), findsOneWidget);
  });

  testWidgets('fila em modo horário pede o slot no diálogo', (tester) async {
    final queues = FakeQueueService(
      queues: {
        'q1': Queue(
          id: 'q1',
          ownerId: 'uid-1',
          name: 'Padaria',
          status: QueueStatus.open,
          createdAt: DateTime(2025, 5, 20),
          mode: QueueMode.schedule,
        ),
      },
      entries: {'q1': const []},
    );
    await pumpApp(tester, panel(queues, FakeManualEntryService()), size: tall);
    await tick(tester);
    await tester.tap(find.byTooltip('Adicionar pessoa'));
    await tester.pumpAndSettle();
    expect(find.text('Horário'), findsWidgets);
  });
}
