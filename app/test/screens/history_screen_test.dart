import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_feedback.dart';
import 'package:qio_app/screens/history_screen.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

const tall = Size(390, 1600);

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

final fixedNow = DateTime(2025, 6, 15, 12);

HistoryScreen screen(FakeQueueService queues) => HistoryScreen(
  queueId: 'q1',
  queueName: 'Padaria',
  queues: queues,
  clock: () => fixedNow,
);

Finder chip(String label) => find.widgetWithText(ChoiceChip, label);

FakeQueueService withData() {
  final now = fixedNow;
  return FakeQueueService(
    history: [
      fakeHistory(
        'h1',
        1,
        name: 'Ana',
        finishedAt: now.subtract(const Duration(minutes: 10)),
      ),
      fakeHistory(
        'h2',
        2,
        name: 'Bruno',
        result: 'no_show',
        finishedAt: now.subtract(const Duration(days: 3)),
      ),
      fakeHistory(
        'h3',
        3,
        name: 'Carla',
        result: 'left',
        finishedAt: now.subtract(const Duration(days: 40)),
      ),
    ],
    feedback: const [QueueFeedback(entryId: 'h1', rating: 5)],
  );
}

void main() {
  testWidgets('shows skeleton before data arrives', (tester) async {
    await pumpApp(tester, screen(withData()), size: tall);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Nenhum atendimento ainda'), findsNothing);
    await tick(tester);
  });

  testWidgets('empty history shows the empty state', (tester) async {
    await pumpApp(tester, screen(FakeQueueService()), size: tall);
    await tick(tester);
    expect(find.text('Nenhum atendimento ainda'), findsOneWidget);
  });

  testWidgets('stream error shows the retry state', (tester) async {
    final queues = FakeQueueService()..historyError = Exception('x');
    await pumpApp(tester, screen(queues), size: tall);
    await tick(tester);
    expect(
      find.text('Não foi possível carregar o histórico. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('lists every entry with rating and metrics for period all', (
    tester,
  ) async {
    await pumpApp(tester, screen(withData()), size: tall);
    await tick(tester);
    expect(find.text('#1 Ana'), findsOneWidget);
    expect(find.text('#2 Bruno'), findsOneWidget);
    expect(find.text('#3 Carla'), findsOneWidget);
    expect(find.textContaining('★ 5'), findsWidgets);
    expect(find.text('5.0 ★ (1)'), findsOneWidget);
    expect(find.text('1 (33%)'), findsOneWidget);
  });

  testWidgets('period chips narrow the list', (tester) async {
    await pumpApp(tester, screen(withData()), size: tall);
    await tick(tester);
    await tester.tap(chip('7 dias'));
    await tick(tester);
    expect(find.text('#1 Ana'), findsOneWidget);
    expect(find.text('#2 Bruno'), findsOneWidget);
    expect(find.text('#3 Carla'), findsNothing);

    await tester.tap(chip('Hoje'));
    await tick(tester);
    expect(find.text('#1 Ana'), findsOneWidget);
    expect(find.text('#2 Bruno'), findsNothing);
  });

  testWidgets('result chips filter and empty filter shows a message', (
    tester,
  ) async {
    await pumpApp(tester, screen(withData()), size: tall);
    await tick(tester);
    await tester.tap(chip('Desistiram'));
    await tick(tester);
    expect(find.text('#3 Carla'), findsOneWidget);
    expect(find.text('#1 Ana'), findsNothing);

    await tester.tap(chip('Hoje'));
    await tick(tester);
    expect(find.text('Nenhum atendimento neste filtro'), findsOneWidget);
  });

  testWidgets('exporting an empty filter warns instead of sharing', (
    tester,
  ) async {
    await pumpApp(tester, screen(withData()), size: tall);
    await tick(tester);
    await tester.tap(chip('Desistiram'));
    await tester.tap(chip('Hoje'));
    await tick(tester);
    await tester.tap(find.byIcon(Icons.file_download_outlined));
    await tick(tester);
    await tester.tap(find.text('Exportar CSV'));
    await tick(tester);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('phone export asks for confirmation and cancel does nothing', (
    tester,
  ) async {
    await pumpApp(tester, screen(withData()), size: tall);
    await tick(tester);
    await tester.tap(find.byIcon(Icons.file_download_outlined));
    await tick(tester);
    expect(find.text('Exportar CSV'), findsOneWidget);
    expect(find.text('Exportar CSV com telefone'), findsOneWidget);
    expect(find.text('Exportar PDF com telefone'), findsOneWidget);
    await tester.tap(find.text('Exportar CSV com telefone'));
    await tick(tester);
    expect(find.text('Incluir telefone?'), findsOneWidget);
    expect(find.textContaining('LGPD'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tick(tester);
    expect(find.text('Incluir telefone?'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('renders in English dark at 320 width', (tester) async {
    await pumpApp(
      tester,
      screen(withData()),
      locale: const Locale('en'),
      themeMode: ThemeMode.dark,
      size: const Size(320, 1600),
    );
    await tick(tester);
    expect(find.text('History'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
