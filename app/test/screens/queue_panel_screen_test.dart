import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_entry.dart';
import 'package:qio_app/screens/queue_panel_screen.dart';
import 'package:qio_app/widgets/qio_button.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

const tall = Size(390, 1800);

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

QueuePanelScreen panel(
  FakeQueueService queues, {
  bool isOwner = true,
  FakeOperatorService? operators,
}) => QueuePanelScreen(
  queueId: 'q1',
  queueName: 'Padaria',
  isOwner: isOwner,
  queues: queues,
  operators: operators ?? FakeOperatorService(),
  groups: FakeGroupService(),
  showTour: false,
);

FakeQueueService service({
  QueueStatus status = QueueStatus.open,
  List<QueueEntry> entries = const [],
}) => FakeQueueService(
  queues: {'q1': fakeQueue('q1', name: 'Padaria', status: status)},
  entries: {'q1': entries},
);

void main() {
  testWidgets('open queue with nobody shows the empty state', (tester) async {
    final queues = service();
    await pumpApp(tester, panel(queues), size: tall);
    await tick(tester);
    expect(find.text('Padaria'), findsWidgets);
    expect(find.text('Aberta'), findsOneWidget);
    expect(find.text('Ninguém chamado'), findsOneWidget);
    expect(find.text('Ninguém na fila'), findsOneWidget);
    expect(find.text('Chamar próximo'), findsOneWidget);
    expect(queues.calls, contains('ensureMirror:q1'));
  });

  testWidgets('waiting entries are listed with the counter', (tester) async {
    final queues = service(
      entries: [
        fakeEntry('e1', 1, name: 'Ana'),
        fakeEntry('e2', 2, name: 'Bruno'),
      ],
    );
    await pumpApp(tester, panel(queues), size: tall);
    await tick(tester);
    expect(find.text('PRÓXIMOS NA FILA'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('Ninguém na fila'), findsNothing);
  });

  testWidgets('call next triggers the service', (tester) async {
    final queues = service(entries: [fakeEntry('e1', 1, name: 'Ana')]);
    await pumpApp(tester, panel(queues), size: tall);
    await tick(tester);
    await tester.tap(find.widgetWithText(QioButton, 'Chamar próximo'));
    await tick(tester);
    expect(queues.calls, contains('callNext:q1'));
  });

  testWidgets('call next with empty result shows a snackbar', (tester) async {
    final queues = service();
    await pumpApp(tester, panel(queues), size: tall);
    await tick(tester);
    await tester.tap(find.widgetWithText(QioButton, 'Chamar próximo'));
    await tick(tester);
    expect(find.text('Ninguém na fila'), findsNWidgets(2));
  });

  testWidgets('call next failure shows the generic error', (tester) async {
    final queues = service()..callNextError = Exception('x');
    await pumpApp(tester, panel(queues), size: tall);
    await tick(tester);
    await tester.tap(find.widgetWithText(QioButton, 'Chamar próximo'));
    await tick(tester);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('called entry shows the current card and can be served', (
    tester,
  ) async {
    final queues = service(
      entries: [fakeEntry('e1', 1, name: 'Ana', status: EntryStatus.called)],
    );
    await pumpApp(tester, panel(queues), size: tall);
    await tick(tester);
    expect(find.text('CHAMANDO AGORA'), findsOneWidget);
    expect(find.text('Chamar de novo'), findsOneWidget);
    await tester.tap(find.widgetWithText(QioButton, 'Atendido'));
    await tick(tester);
    expect(queues.calls, contains('served:e1'));
  });

  testWidgets('call next is disabled while an entry is being served', (
    tester,
  ) async {
    final queues = service(
      entries: [fakeEntry('e1', 1, status: EntryStatus.called)],
    );
    await pumpApp(tester, panel(queues), size: tall);
    await tick(tester);
    await tester.tap(
      find.widgetWithText(QioButton, 'Chamar próximo'),
      warnIfMissed: false,
    );
    await tick(tester);
    expect(queues.calls, isNot(contains('callNext:q1')));
  });

  testWidgets('closed queue shows hint and delete for the owner', (
    tester,
  ) async {
    final queues = service(status: QueueStatus.closed);
    await pumpApp(tester, panel(queues), size: tall);
    await tick(tester);
    expect(find.text('Fila fechada'), findsOneWidget);
    expect(
      find.text('A fila está fechada. Você pode reabri-la ou excluí-la.'),
      findsOneWidget,
    );
    expect(find.text('Excluir fila'), findsOneWidget);
    expect(find.text('Chamar próximo'), findsNothing);
    expect(find.text('Reabrir'), findsOneWidget);
  });

  testWidgets('closed queue for an operator hides owner controls', (
    tester,
  ) async {
    final queues = service(status: QueueStatus.closed);
    await pumpApp(tester, panel(queues, isOwner: false), size: tall);
    await tick(tester);
    expect(
      find.text('A fila está fechada. Aguarde o dono reabrir.'),
      findsOneWidget,
    );
    expect(find.text('Excluir fila'), findsNothing);
    expect(find.text('Reabrir'), findsNothing);
  });

  testWidgets('paused queue offers reopen', (tester) async {
    final queues = service(status: QueueStatus.paused);
    await pumpApp(tester, panel(queues), size: tall);
    await tick(tester);
    expect(find.text('Pausada'), findsOneWidget);
    await tester.tap(find.text('Reabrir'));
    await tick(tester);
    expect(queues.calls, contains('status:q1:open'));
  });

  testWidgets('operator without access sees the access-ended dialog', (
    tester,
  ) async {
    final queues = service();
    final operators = FakeOperatorService();
    addTearDown(operators.access.close);
    await pumpApp(
      tester,
      panel(queues, isOwner: false, operators: operators),
      size: tall,
    );
    operators.access.add(false);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tick(tester);
    expect(find.text('Acesso encerrado'), findsOneWidget);
  });

  testWidgets('renders in English dark at 320 width', (tester) async {
    final queues = service(entries: [fakeEntry('e1', 1, name: 'Ana')]);
    await pumpApp(
      tester,
      panel(queues),
      locale: const Locale('en'),
      themeMode: ThemeMode.dark,
      size: const Size(320, 1800),
    );
    await tick(tester);
    expect(find.text('Call next'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
