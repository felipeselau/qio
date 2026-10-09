import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_slot.dart';
import 'package:qio_app/screens/create_queue_screen.dart';
import 'package:qio_app/widgets/queue_panel/slots_editor.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

const tall = Size(390, 1800);

QueueSlot slot(String id, String start, [int capacity = 2]) =>
    QueueSlot(id: id, start: start, capacity: capacity);

class Harness extends StatefulWidget {
  const Harness({
    super.key,
    this.mode = QueueMode.queue,
    this.slots = const [],
    this.initialSlots = const [],
  });

  final QueueMode mode;
  final List<QueueSlot> slots;
  final List<QueueSlot> initialSlots;

  @override
  State<Harness> createState() => HarnessState();
}

class HarnessState extends State<Harness> {
  late QueueMode mode = widget.mode;
  late List<QueueSlot> slots = [...widget.slots];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      child: SlotsEditor(
        mode: mode,
        slots: slots,
        initialSlots: widget.initialSlots,
        onChanged: (m, s) => setState(() {
          mode = m;
          slots = s;
        }),
      ),
    ),
  );
}

void main() {
  testWidgets('queue mode hides the slot list; switching shows the hint', (
    tester,
  ) async {
    await pumpApp(tester, const Harness(), size: tall);
    expect(find.text('Adicionar horário'), findsNothing);
    await tester.tap(find.text('Hora marcada'));
    await tester.pump();
    expect(find.text('Adicionar horário'), findsOneWidget);
    expect(
      find.text('Fuso America/Sao_Paulo; repetem todo dia'),
      findsOneWidget,
    );
  });

  testWidgets('schedule mode lists slots, adjusts capacity and removes', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Harness(
        mode: QueueMode.schedule,
        slots: [slot('b', '10:00'), slot('a', '09:00')],
      ),
      size: tall,
    );
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('Vagas: 2'), findsNWidgets(2));

    await tester.tap(find.byTooltip('+').first);
    await tester.pump();
    expect(find.text('Vagas: 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Remover horário').first);
    await tester.pump();
    expect(find.text('09:00'), findsNothing);
    expect(find.text('10:00'), findsOneWidget);
  });

  testWidgets('add button is disabled at 20 slots', (tester) async {
    final slots = [
      for (var i = 0; i < 20; i++)
        slot('s$i', '${i.toString().padLeft(2, '0')}:00'),
    ];
    await pumpApp(
      tester,
      Harness(mode: QueueMode.schedule, slots: slots),
      size: const Size(390, 5000),
    );
    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Adicionar horário'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('warns when an existing slot time was changed', (tester) async {
    await pumpApp(
      tester,
      Harness(
        mode: QueueMode.schedule,
        slots: [slot('a', '09:30')],
        initialSlots: [slot('a', '09:00')],
      ),
      size: tall,
    );
    expect(find.textContaining('continua na vaga antiga'), findsOneWidget);
  });

  testWidgets('tile saves valid slots through the service', (tester) async {
    final queues = FakeQueueService();
    await pumpApp(
      tester,
      Scaffold(
        body: QueueSlotsTile(
          queueId: 'q1',
          mode: QueueMode.schedule,
          slots: [slot('a', '09:00')],
          queues: queues,
        ),
      ),
      size: tall,
    );
    expect(find.textContaining('1 horários'), findsOneWidget);
    await tester.tap(find.byType(QueueSlotsTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(queues.calls, contains('modeSlots:q1:schedule:1'));
    expect(queues.savedSlots!.single.start, '09:00');
  });

  testWidgets('tile blocks schedule mode without slots', (tester) async {
    final queues = FakeQueueService();
    await pumpApp(
      tester,
      Scaffold(
        body: QueueSlotsTile(
          queueId: 'q1',
          mode: QueueMode.schedule,
          slots: const [],
          queues: queues,
        ),
      ),
      size: tall,
    );
    await tester.tap(find.byType(QueueSlotsTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Adicione ao menos um horário'), findsOneWidget);
    expect(queues.calls, isEmpty);
  });

  testWidgets('create screen requires slots in schedule mode', (tester) async {
    final queues = FakeQueueService();
    await pumpApp(
      tester,
      CreateQueueScreen(queues: queues, groups: FakeGroupService()),
      size: tall,
    );
    await tester.enterText(find.byType(TextFormField).first, 'Clínica');
    await tester.tap(find.text('Opções avançadas'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hora marcada'));
    await tester.tap(find.text('Hora marcada'));
    await tester.pump();

    await tester.ensureVisible(find.text('Criar fila'));
    await tester.tap(find.text('Criar fila'));
    await tester.pump();
    expect(find.text('Adicione ao menos um horário'), findsOneWidget);
    expect(queues.calls, isEmpty);

    await tester.ensureVisible(find.text('Adicionar horário'));
    await tester.tap(find.text('Adicionar horário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('09:00'), findsOneWidget);

    await tester.ensureVisible(find.text('Criar fila'));
    await tester.tap(find.text('Criar fila'));
    await tester.pump();
    expect(queues.calls, ['create:Clínica:schedule:1']);
    expect(queues.createdSlots!.single.start, '09:00');
    await tester.pumpAndSettle();
  });
}
