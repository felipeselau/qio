import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/screens/create_queue_screen.dart';
import 'package:qio_app/screens/queue_panel_screen.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

const tall = Size(390, 1800);

Future<FakeQueueService> pumpCreate(WidgetTester tester) async {
  final queues = FakeQueueService();
  await pumpApp(
    tester,
    CreateQueueScreen(queues: queues, groups: FakeGroupService()),
    size: tall,
  );
  return queues;
}

void main() {
  testWidgets('creates a queue with only the name', (tester) async {
    final queues = await pumpCreate(tester);
    await tester.enterText(find.byType(TextFormField).first, '  Padaria ');
    await tester.tap(find.text('Criar fila'));
    await tester.pump();
    await tester.pump();

    expect(queues.calls, ['create:Padaria:queue:0']);
    final args = queues.createdArgs!;
    expect(args.description, isNull);
    expect(args.avgServiceMin, isNull);
    expect(args.maxWaiting, 0);
    expect(args.groupId, isNull);
  });

  testWidgets('name is required and advanced options start collapsed', (
    tester,
  ) async {
    final queues = await pumpCreate(tester);
    expect(find.text('Descrição (opcional)'), findsNothing);
    expect(find.text('Opções avançadas'), findsOneWidget);

    await tester.tap(find.text('Criar fila'));
    await tester.pump();
    expect(find.text('Informe o nome'), findsOneWidget);
    expect(queues.calls, isEmpty);
    expect(find.text('Descrição (opcional)'), findsNothing);
  });

  testWidgets('advanced values reach the service', (tester) async {
    final queues = await pumpCreate(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Clínica');
    await tester.tap(find.text('Opções avançadas'));
    await tester.pumpAndSettle();
    expect(find.text('Descrição (opcional)'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'Sala 2');
    await tester.enterText(fields.at(2), '20');
    await tester.enterText(fields.at(3), '30');
    await tester.ensureVisible(find.text('Criar fila'));
    await tester.tap(find.text('Criar fila'));
    await tester.pump();
    await tester.pump();

    final args = queues.createdArgs!;
    expect(args.description, 'Sala 2');
    expect(args.avgServiceMin, 20);
    expect(args.maxWaiting, 30);
  });

  testWidgets('invalid advanced value reopens the section', (tester) async {
    final queues = await pumpCreate(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Clínica');
    await tester.tap(find.text('Opções avançadas'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), '241');
    await tester.tap(find.text('Opções avançadas'));
    await tester.pumpAndSettle();
    expect(find.text('Descrição (opcional)'), findsNothing);

    await tester.tap(find.text('Criar fila'));
    await tester.pumpAndSettle();
    expect(find.text('Informe de 1 a 240 minutos'), findsOneWidget);
    expect(queues.calls, isEmpty);
  });

  testWidgets('back button is labeled and guards unsaved input', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CreateQueueScreen(
                queues: FakeQueueService(),
                groups: FakeGroupService(),
              ),
            ),
          ),
          child: const Text('abrir'),
        ),
      ),
      size: tall,
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byTooltip('Voltar'), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    await tester.enterText(find.byType(TextFormField).first, 'Algo');
    await tester.pump();
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Continuar editando'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('panel back button is labeled', (tester) async {
    final handle = tester.ensureSemantics();
    final queues = FakeQueueService(
      queues: {'q1': fakeQueue('q1', name: 'Padaria')},
    );
    await pumpApp(
      tester,
      QueuePanelScreen(
        queueId: 'q1',
        queueName: 'Padaria',
        queues: queues,
        operators: FakeOperatorService(),
        groups: FakeGroupService(),
        showTour: false,
      ),
      size: tall,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byTooltip('Voltar'), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
