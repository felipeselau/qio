import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/screens/edit_queue_screen.dart';
import 'package:qio_app/screens/queue_panel_screen.dart';
import 'package:qio_app/screens/queue_settings_screen.dart';
import 'package:qio_app/widgets/queue_panel/duplicate_queue_tile.dart';
import 'package:qio_app/widgets/queue_panel/edit_queue_tile.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

const tall = Size(390, 2400);

Queue sample() => Queue(
  id: 'q1',
  ownerId: 'uid-1',
  name: 'Padaria',
  description: 'Balcão 1',
  avgServiceMin: 7,
  createdAt: DateTime(2025, 5, 20),
);

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('edit form starts filled and saves trimmed values', (
    tester,
  ) async {
    final queues = FakeQueueService();
    await pumpApp(
      tester,
      EditQueueScreen(queue: sample(), queues: queues),
      size: tall,
    );
    expect(find.text('Padaria'), findsOneWidget);
    expect(find.text('Balcão 1'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '  Padaria 2 ');
    await tester.enterText(find.byType(TextFormField).at(1), '');
    await tester.enterText(find.byType(TextFormField).at(2), '12');
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    await tester.pump();

    expect(queues.calls, contains('info:q1:Padaria 2::12'));
  });

  testWidgets('invalid values block the save and show errors', (tester) async {
    final queues = FakeQueueService();
    await pumpApp(
      tester,
      EditQueueScreen(queue: sample(), queues: queues),
      size: tall,
    );
    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(2), '241');
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(find.text('Informe o nome'), findsOneWidget);
    expect(find.text('Informe de 1 a 240 minutos'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'x' * 61);
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(find.text('No máximo 60 caracteres'), findsOneWidget);
    expect(queues.calls.where((c) => c.startsWith('info:')), isEmpty);
  });

  testWidgets('service error keeps the screen and shows a snackbar', (
    tester,
  ) async {
    final queues = FakeQueueService()..updateInfoError = Exception('boom');
    await pumpApp(
      tester,
      EditQueueScreen(queue: sample(), queues: queues),
      size: tall,
    );
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(EditQueueScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('panel shows edit and duplicate tiles for the owner', (
    tester,
  ) async {
    final queues = FakeQueueService(queues: {'q1': sample()});
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
    await tick(tester);
    await tester.tap(find.byTooltip('Configurações da fila'));
    await tick(tester);
    expect(find.byType(EditQueueTile), findsOneWidget);
    expect(find.byType(DuplicateQueueTile), findsOneWidget);

    await tester.tap(find.byType(EditQueueTile));
    await tick(tester);
    expect(find.byType(EditQueueScreen), findsOneWidget);
  });

  testWidgets('operators do not see edit or duplicate', (tester) async {
    final queues = FakeQueueService(queues: {'q1': sample()});
    await pumpApp(
      tester,
      QueuePanelScreen(
        queueId: 'q1',
        queueName: 'Padaria',
        isOwner: false,
        queues: queues,
        operators: FakeOperatorService(),
        showTour: false,
      ),
      size: tall,
    );
    await tick(tester);
    expect(find.byType(EditQueueTile), findsNothing);
    expect(find.byType(DuplicateQueueTile), findsNothing);
  });

  testWidgets('duplicate names the copy and opens its panel', (tester) async {
    final queues = FakeQueueService(queues: {'q1': sample()});
    await pumpApp(
      tester,
      Scaffold(
        body: DuplicateQueueTile(
          queue: sample(),
          queues: queues,
          panelBuilder: (copy) => Text('painel ${copy.id} ${copy.name}'),
        ),
      ),
    );
    await tester.tap(find.byType(DuplicateQueueTile));
    await tick(tester);

    expect(queues.calls, contains('duplicate:q1:Padaria (cópia)'));
    expect(find.text('painel copy Padaria (cópia)'), findsOneWidget);
  });

  testWidgets('duplicate failure shows an error and stays on the panel', (
    tester,
  ) async {
    final queues = FakeQueueService(queues: {'q1': sample()})
      ..duplicateError = Exception('boom');
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
    await tick(tester);
    await tester.tap(find.byTooltip('Configurações da fila'));
    await tick(tester);
    await tester.tap(find.byType(DuplicateQueueTile));
    await tick(tester);
    expect(find.byType(QueueSettingsScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('legacy long name does not block editing the average time', (
    tester,
  ) async {
    final queues = FakeQueueService();
    final legacy = Queue(
      id: 'q1',
      ownerId: 'uid-1',
      name: 'x' * 80,
      avgServiceMin: 7,
      createdAt: DateTime(2025, 5, 20),
    );
    await pumpApp(
      tester,
      EditQueueScreen(queue: legacy, queues: queues),
      size: tall,
    );
    await tester.enterText(find.byType(TextFormField).at(2), '9');
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    await tester.pump();
    expect(find.text('No máximo 60 caracteres'), findsNothing);
    expect(queues.calls.single, endsWith(':9'));
  });

  testWidgets('shows the automatic estimate hint', (tester) async {
    await pumpApp(
      tester,
      EditQueueScreen(queue: sample(), queues: FakeQueueService()),
      size: tall,
    );
    expect(find.textContaining('estimativa automática'), findsOneWidget);
  });

  testWidgets('validation failure from the service shows the field message', (
    tester,
  ) async {
    final queues = FakeQueueService()
      ..updateInfoError = const FormatException('nameTooLong');
    await pumpApp(
      tester,
      EditQueueScreen(queue: sample(), queues: queues),
      size: tall,
    );
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    await tester.pump();
    expect(find.text('No máximo 60 caracteres'), findsOneWidget);
  });

  testWidgets('unsaved changes ask before leaving', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  EditQueueScreen(queue: sample(), queues: FakeQueueService()),
            ),
          ),
          child: const Text('abrir'),
        ),
      ),
      size: tall,
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(EditQueueScreen), findsNothing);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Outro');
    await tester.pump();
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Continuar editando'), findsOneWidget);
    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();
    expect(find.byType(EditQueueScreen), findsOneWidget);
  });
}
