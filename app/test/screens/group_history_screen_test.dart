import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_feedback.dart';
import 'package:qio_app/models/queue_group.dart';
import 'package:qio_app/models/queue_history_input.dart';
import 'package:qio_app/screens/history_screen.dart';
import 'package:qio_app/screens/metrics_screen.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

final fixedNow = DateTime(2025, 6, 15, 12);

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

class PerQueueFake extends FakeQueueService {
  PerQueueFake(this.byQueue, {this.feedbackByQueue = const {}});

  final Map<String, List<HistoryEntry>> byQueue;
  final Map<String, List<QueueFeedback>> feedbackByQueue;
  final fetched = <String>[];

  @override
  Future<List<HistoryEntry>> fetchHistory(
    String queueId, {
    int limit = 500,
  }) async {
    fetched.add(queueId);
    return byQueue[queueId] ?? const [];
  }

  @override
  Future<List<QueueFeedback>> fetchFeedback(String queueId) async =>
      feedbackByQueue[queueId] ?? const [];
}

HistoryEntry h(
  String id,
  int ticket,
  String name,
  Duration ago, {
  String result = 'served',
}) => fakeHistory(
  id,
  ticket,
  name: name,
  result: result,
  finishedAt: fixedNow.subtract(ago),
);

final queues = [
  fakeQueue('a', name: 'Padaria'),
  fakeQueue('b', name: 'Clinica'),
];

PerQueueFake data() => PerQueueFake(
  {
    'a': [
      h('a1', 1, 'Ana', const Duration(minutes: 10)),
      h('a2', 2, 'Bruno', const Duration(days: 40), result: 'left'),
    ],
    'b': [
      h('b1', 3, 'Carla', const Duration(minutes: 5)),
      h('b2', 4, 'Davi', const Duration(days: 3), result: 'no_show'),
    ],
  },
  feedbackByQueue: {
    'a': const [QueueFeedback(entryId: 'a1', rating: 4)],
    'b': const [QueueFeedback(entryId: 'b1', rating: 5)],
  },
);

HistoryScreen screen(PerQueueFake svc, {List<Queue>? list}) =>
    HistoryScreen.group(
      groupName: 'Balcão',
      groupQueues: list ?? queues,
      queues: svc,
      clock: () => fixedNow,
    );

Finder chip(String label) => find.widgetWithText(ChoiceChip, label);

const tall = Size(390, 2400);

void main() {
  testWidgets('lists the merged entries with the origin queue and rating', (
    tester,
  ) async {
    final svc = data();
    await pumpApp(tester, screen(svc), size: tall);
    await tick(tester);
    expect(find.text('Histórico do grupo'), findsOneWidget);
    expect(find.text('Balcão'), findsOneWidget);
    expect(svc.fetched.toSet(), {'a', 'b'});
    expect(find.text('Fila: Padaria'), findsNWidgets(2));
    expect(find.text('Fila: Clinica'), findsNWidgets(2));
    final order = [
      for (final n in ['#3 Carla', '#1 Ana', '#4 Davi', '#2 Bruno'])
        tester.getTopLeft(find.text(n)).dy,
    ];
    expect(order, [...order]..sort());
    expect(find.text('4.5 ★ (2)'), findsOneWidget);
    expect(find.textContaining('★ 5'), findsWidgets);
    expect(find.text('Desistiu'), findsOneWidget);
    expect(find.textContaining('mais recentes de cada fila'), findsNothing);
  });

  testWidgets('result and period filters apply to the merged list', (
    tester,
  ) async {
    await pumpApp(tester, screen(data()), size: tall);
    await tick(tester);
    await tester.tap(chip('Desistiram'));
    await tick(tester);
    expect(find.text('#2 Bruno'), findsOneWidget);
    expect(find.text('#1 Ana'), findsNothing);
    await tester.tap(chip('Hoje'));
    await tick(tester);
    expect(find.text('Nenhum atendimento neste filtro'), findsOneWidget);
    await tester.tap(chip('Todos'));
    await tester.tap(chip('Hoje'));
    await tick(tester);
    expect(find.text('#3 Carla'), findsOneWidget);
    expect(find.text('#4 Davi'), findsNothing);
  });

  testWidgets('warns about queues truncated at the per-queue limit', (
    tester,
  ) async {
    final svc = PerQueueFake({
      'a': [
        for (var i = 0; i < 500; i++)
          h('a$i', i, 'N$i', Duration(minutes: i + 1)),
      ],
      'b': [h('b1', 1, 'Carla', const Duration(minutes: 5))],
    });
    await pumpApp(tester, screen(svc), size: tall);
    await tick(tester);
    expect(
      find.textContaining('500 registros mais recentes de cada fila'),
      findsOneWidget,
    );
    expect(find.textContaining('Padaria'), findsWidgets);
    final more = find.byKey(const ValueKey('history-show-more'));
    await tester.scrollUntilVisible(
      more,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mostrar mais (50 de 501)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('history-show-more')));
    await tick(tester);
    await tester.scrollUntilVisible(
      more,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mostrar mais (100 de 501)'), findsOneWidget);
  });

  testWidgets('group without queues shows the empty state', (tester) async {
    await pumpApp(tester, screen(data(), list: const []), size: tall);
    await tick(tester);
    expect(find.text('Nenhuma fila neste grupo'), findsOneWidget);
  });

  testWidgets('queues without history show the no history state', (
    tester,
  ) async {
    await pumpApp(tester, screen(PerQueueFake({})), size: tall);
    await tick(tester);
    expect(find.text('Nenhum atendimento ainda'), findsOneWidget);
  });

  testWidgets('phone export keeps the LGPD confirmation', (tester) async {
    await pumpApp(tester, screen(data()), size: tall);
    await tick(tester);
    await tester.tap(find.byIcon(Icons.file_download_outlined));
    await tick(tester);
    expect(find.text('Exportar CSV'), findsOneWidget);
    await tester.tap(find.text('Exportar PDF com telefone'));
    await tick(tester);
    expect(find.text('Incluir telefone?'), findsOneWidget);
    expect(find.textContaining('LGPD'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tick(tester);
    expect(find.text('Incluir telefone?'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  for (final w in [320.0, 900.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('renders at $w px with text scale $scale', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(
          tester,
          screen(data()),
          locale: const Locale('en'),
          size: Size(w, 2400),
        );
        await tick(tester);
        expect(find.text('Group history'), findsOneWidget);
        expect(find.text('Queue: Padaria'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('metrics opens the group history only in group scope', (
    tester,
  ) async {
    final svc = data();
    Queue gq(String id, String name, {String? groupId}) =>
        fakeQueue(id, name: name, groupId: groupId);
    await pumpApp(
      tester,
      MetricsScreen(
        clock: () => fixedNow,
        queues: svc,
        groupsLoader: () async => [
          QueueGroup(id: 'g1', name: 'Balcão', createdAt: DateTime(2025)),
        ],
        loader: () async => [
          QueueHistoryInput(
            gq('a', 'Padaria', groupId: 'g1'),
            [h('a1', 1, 'Ana', const Duration(minutes: 10))],
            const [],
            const [],
          ),
          QueueHistoryInput(
            gq('b', 'Clinica', groupId: 'g1'),
            [h('b1', 3, 'Carla', const Duration(minutes: 5))],
            const [],
            const [],
          ),
        ],
      ),
      size: tall,
    );
    await tick(tester);
    expect(find.byKey(const ValueKey('group-history-open')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('scope-picker')));
    await tick(tester);
    await tester.tap(find.text('Balcão').last);
    await tick(tester);
    await tester.tap(find.byKey(const ValueKey('group-history-open')));
    await tick(tester);
    await tick(tester);
    expect(find.text('Histórico do grupo'), findsOneWidget);
    expect(find.text('#3 Carla'), findsOneWidget);
    expect(find.text('Fila: Clinica'), findsNWidgets(2));
  });
}
