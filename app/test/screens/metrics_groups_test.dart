import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_group.dart';
import 'package:qio_app/models/queue_history_input.dart';
import 'package:qio_app/screens/metrics_screen.dart';
import 'package:qio_app/services/queue_analytics.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

const tall = Size(390, 2400);
final fixedNow = DateTime(2025, 6, 15, 12);

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

QueueGroup g(String id, String name) =>
    QueueGroup(id: id, name: name, createdAt: DateTime(2025));

Queue q(String id, String name, {String? groupId}) => Queue(
  id: id,
  ownerId: 'uid-1',
  name: name,
  createdAt: DateTime(2025, 5, 20),
  groupId: groupId,
);

HistoryEntry h(String id) => fakeHistory(
  id,
  1,
  finishedAt: fixedNow.subtract(const Duration(minutes: 5)),
);

QueueHistoryInput input(Queue queue, List<HistoryEntry> entries) =>
    QueueHistoryInput(queue, entries, const [], const []);

Future<List<QueueHistoryInput>> small() async => [
  input(q('a', 'Padaria', groupId: 'g1'), [h('1')]),
  input(q('b', 'Clinica', groupId: 'g2'), [h('2'), h('3')]),
  input(q('c', 'Avulsa'), [h('4')]),
];

Future<void> pumpGrouped(
  WidgetTester tester, {
  Size size = tall,
  Future<List<QueueHistoryInput>> Function()? loader,
  List<QueueGroup>? groups,
}) async {
  await pumpApp(
    tester,
    MetricsScreen(
      clock: () => fixedNow,
      loader: loader ?? small,
      groupsLoader: () async =>
          groups ?? [g('g1', 'Balcão'), g('g2', 'Exames')],
    ),
    size: size,
  );
  await tick(tester);
}

Future<void> openScope(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('scope-picker')));
  await tick(tester);
}

void main() {
  testWidgets('sem grupos a seção não aparece e o seletor é o simples', (
    tester,
  ) async {
    await pumpApp(
      tester,
      MetricsScreen(clock: () => fixedNow, loader: small),
      size: tall,
    );
    await tick(tester);
    expect(find.text('Por grupo'), findsNothing);
    expect(find.byType(DropdownButton<MetricsScope>), findsOneWidget);
    expect(find.byKey(const ValueKey('scope-picker')), findsNothing);
  });

  testWidgets('mostra uma linha por grupo mais Sem grupo', (tester) async {
    await pumpGrouped(tester);
    expect(find.text('Por grupo'), findsOneWidget);
    expect(find.byKey(const ValueKey('cmp-row-g1')), findsOneWidget);
    expect(find.byKey(const ValueKey('cmp-row-g2')), findsOneWidget);
    expect(find.byKey(const ValueKey('cmp-row-none')), findsOneWidget);
    expect(find.text('Exames'), findsOneWidget);
    expect(find.text('Sem grupo'), findsOneWidget);
    expect(find.text('Filas mais ativas'), findsOneWidget);
  });

  testWidgets('tocar numa linha troca o escopo para o grupo', (tester) async {
    await pumpGrouped(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('cmp-row-g2')));
    await tester.tap(find.byKey(const ValueKey('cmp-row-g2')));
    await tick(tester);
    expect(find.text('Grupo: Exames'), findsOneWidget);
    expect(find.text('Por grupo'), findsNothing);
    expect(find.text('Comparativo entre filas do grupo'), findsOneWidget);
    expect(find.byKey(const ValueKey('cmp-row-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('cmp-row-a')), findsNothing);
  });

  testWidgets('tocar em Sem grupo filtra as filas sem grupo', (tester) async {
    await pumpGrouped(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('cmp-row-none')));
    await tester.tap(find.byKey(const ValueKey('cmp-row-none')));
    await tick(tester);
    expect(find.text('Filas sem grupo'), findsOneWidget);
    expect(find.text('Avulsa'), findsWidgets);
    expect(find.text('Padaria'), findsNothing);
  });

  testWidgets('o seletor mostra seções e filas dentro do grupo', (
    tester,
  ) async {
    await pumpGrouped(tester);
    await openScope(tester);
    expect(find.byKey(const ValueKey('scope-all-')), findsOneWidget);
    expect(find.byKey(const ValueKey('scope-group-g1')), findsOneWidget);
    expect(find.byKey(const ValueKey('scope-queue-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('scope-ungrouped-')), findsOneWidget);
    expect(find.byKey(const ValueKey('scope-queue-c')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scope-queue-b')));
    await tick(tester);
    expect(find.text('Fila: Clinica'), findsOneWidget);
    expect(find.text('Por grupo'), findsNothing);
  });

  testWidgets('busca no seletor filtra grupos e filas', (tester) async {
    await pumpGrouped(tester);
    await openScope(tester);
    await tester.enterText(find.byKey(const ValueKey('scope-search')), 'clin');
    await tester.pump();
    expect(find.byKey(const ValueKey('scope-queue-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('scope-group-g2')), findsOneWidget);
    expect(find.byKey(const ValueKey('scope-queue-a')), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('scope-search')), 'zzz');
    await tester.pump();
    expect(find.text('Nada encontrado'), findsOneWidget);
  });

  testWidgets('com 20 grupos e 20 filas todo escopo sai em 2 toques', (
    tester,
  ) async {
    String two(int i) => i.toString().padLeft(2, '0');
    final groups = [for (var i = 1; i <= 20; i++) g('g$i', 'Grupo ${two(i)}')];
    final data = [
      for (var i = 1; i <= 20; i++)
        input(q('q$i', 'Fila ${two(i)}', groupId: i <= 15 ? 'g$i' : null), [
          h('e$i'),
        ]),
    ];
    final targets = <(String, String)>[
      ('scope-all-', 'Todas as filas'),
      ('scope-group-g1', 'Grupo: Grupo 01'),
      ('scope-group-g20', 'Grupo: Grupo 20'),
      ('scope-queue-q1', 'Fila: Fila 01'),
      ('scope-queue-q15', 'Fila: Fila 15'),
      ('scope-queue-q20', 'Fila: Fila 20'),
      ('scope-ungrouped-', 'Filas sem grupo'),
    ];
    for (final (key, label) in targets) {
      await pumpGrouped(
        tester,
        size: const Size(390, 844),
        loader: () async => data,
        groups: groups,
      );
      await tester.tap(find.byKey(const ValueKey('scope-picker')));
      await tick(tester);
      final target = find.byKey(ValueKey(key));
      await tester.scrollUntilVisible(
        target,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(target);
      await tester.pump();
      await tester.tap(target);
      await tick(tester);
      expect(find.text(label), findsWidgets, reason: key);
      expect(find.byType(BottomSheet), findsNothing);
    }
  });

  testWidgets('seletor a 320 px com texto 2.0 sem estouro', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await pumpGrouped(tester, size: const Size(320, 800));
    expect(tester.takeException(), isNull);
    await openScope(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('scope-group-g1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scope-all-')));
    await tick(tester);
  });

  testWidgets('900 px sem estouro', (tester) async {
    await pumpGrouped(tester, size: const Size(900, 2400));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('cmp-row-g1')), findsOneWidget);
    await openScope(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('scope-group-g1')), findsOneWidget);
  });

  testWidgets('o seletor tem rótulo falado e alvo de 48 dp', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpGrouped(tester);
    expect(
      find.bySemanticsLabel('Escopo das métricas: Todas as filas'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('scope-picker'))).height,
      greaterThanOrEqualTo(48),
    );
    handle.dispose();
  });

  testWidgets('dark theme renders the group view', (tester) async {
    await pumpApp(
      tester,
      MetricsScreen(
        clock: () => fixedNow,
        loader: small,
        groupsLoader: () async => [g('g1', 'Balcão')],
      ),
      size: tall,
      themeMode: ThemeMode.dark,
    );
    await tick(tester);
    expect(find.text('Por grupo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
