import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/operator.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_group.dart';
import 'package:qio_app/screens/home_screen.dart';
import 'package:qio_app/services/home_grouping.dart';

import '../helpers/fake_auth.dart';
import '../helpers/fake_collapse_store.dart';
import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

QueueGroup qg(String id, String name) =>
    QueueGroup(id: id, name: name, createdAt: DateTime(2025, 1, 1));

Future<void> pumpTall(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('pt'),
  Size size = const Size(390, 2400),
}) => pumpApp(tester, child, locale: locale, size: size);

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

HomeScreen homeWith({
  required List<Queue> queues,
  List<QueueGroup> groups = const [],
  Map<String, int> waiting = const {},
  List<QueueOperator> operating = const [],
  Map<String, Queue> extra = const {},
  GroupCollapseStore? store,
}) => HomeScreen(
  auth: FakeAuthService(user: FakeUser(displayName: 'Maria')),
  queues: FakeQueueService(
    ownerQueues: queues,
    queues: extra,
    waitingCounts: waiting,
  ),
  operators: FakeOperatorService(operating: operating),
  groups: FakeGroupService(groups: groups),
  collapseStore: store ?? MemoryCollapseStore(),
  enableIntegrations: false,
);

final _groups = [qg('g1', 'Loja Centro'), qg('g2', 'Anexo')];

List<Queue> _sample() => [
  fakeQueue('a', name: 'Caixa 1', groupId: 'g1'),
  fakeQueue('b', name: 'Caixa 2', groupId: 'g1'),
  fakeQueue('c', name: 'Caixa 3', groupId: 'g1'),
  fakeQueue('d', name: 'Balcao', groupId: 'g2'),
  fakeQueue('e', name: 'Solta'),
  fakeQueue('f', name: 'Orfa', groupId: 'gone'),
];

void main() {
  testWidgets('groups queues by group and sends orphans to Sem grupo', (
    tester,
  ) async {
    await pumpTall(tester, homeWith(queues: _sample(), groups: _groups));
    await tick(tester);

    final anexo = tester.getTopLeft(find.text('Anexo')).dy;
    final centro = tester.getTopLeft(find.text('Loja Centro')).dy;
    final none = tester.getTopLeft(find.text('Sem grupo')).dy;
    expect(anexo, lessThan(centro));
    expect(centro, lessThan(none));
    expect(
      tester.getTopLeft(find.text('Balcao')).dy,
      allOf(greaterThan(anexo), lessThan(centro)),
    );
    expect(tester.getTopLeft(find.text('Solta')).dy, greaterThan(none));
    expect(tester.getTopLeft(find.text('Orfa')).dy, greaterThan(none));
  });

  testWidgets('zero groups keeps the flat list', (tester) async {
    await pumpTall(tester, homeWith(queues: [fakeQueue('a', name: 'Solta')]));
    await tick(tester);
    expect(find.text('Solta'), findsOneWidget);
    expect(find.text('Sem grupo'), findsNothing);
    expect(find.byIcon(Icons.expand_more), findsNothing);
  });

  testWidgets('groups without queues keep the flat list', (tester) async {
    await pumpTall(
      tester,
      homeWith(
        queues: [
          fakeQueue('a', name: 'Solta'),
          fakeQueue('b', groupId: 'x'),
        ],
        groups: _groups,
      ),
    );
    await tick(tester);
    expect(find.text('Sem grupo'), findsNothing);
    expect(find.text('Loja Centro'), findsNothing);
    expect(find.byIcon(Icons.expand_more), findsNothing);
  });

  testWidgets('header shows queue count and summed waiting', (tester) async {
    await pumpTall(
      tester,
      homeWith(
        queues: _sample(),
        groups: _groups,
        waiting: {'a': 5, 'b': 4, 'c': 3, 'd': 1},
      ),
    );
    await tick(tester);
    expect(find.text('3 filas · 12 esperando'), findsOneWidget);
    expect(find.text('1 fila · 1 esperando'), findsOneWidget);
    expect(find.text('2 filas · 0 esperando'), findsOneWidget);
  });

  testWidgets('tap collapses and expands and persists per uid', (tester) async {
    final store = MemoryCollapseStore();
    await pumpTall(
      tester,
      homeWith(queues: _sample(), groups: _groups, store: store),
    );
    await tick(tester);
    expect(find.text('Caixa 1'), findsOneWidget);

    await tester.tap(find.text('Loja Centro'));
    await tick(tester);
    expect(find.text('Caixa 1'), findsNothing);
    expect(find.text('Balcao'), findsOneWidget);
    expect(store.saved, {'g1'});

    await tester.tap(find.text('Loja Centro'));
    await tick(tester);
    expect(find.text('Caixa 1'), findsOneWidget);
    expect(store.saved, isEmpty);

    await tester.tap(find.text('Sem grupo'));
    await tick(tester);
    expect(find.text('Solta'), findsNothing);
    expect(store.saved, {ungroupedSectionId});
  });

  testWidgets('collapsed state is restored from the store', (tester) async {
    final store = MemoryCollapseStore({'g1'});
    await pumpTall(
      tester,
      homeWith(queues: _sample(), groups: _groups, store: store),
    );
    await tick(tester);
    expect(find.text('Caixa 1'), findsNothing);
    expect(find.text('Loja Centro'), findsOneWidget);
    expect(find.text('Balcao'), findsOneWidget);
  });

  testWidgets('collapse works without animations', (tester) async {
    await pumpTall(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: homeWith(queues: _sample(), groups: _groups),
        ),
      ),
    );
    await tick(tester);
    await tester.tap(find.text('Loja Centro'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Caixa 1'), findsNothing);
  });

  group('search inside groups', () {
    List<Queue> many() => [
      fakeQueue('a', name: 'Alfa', groupId: 'g1'),
      fakeQueue('b', name: 'Beta', groupId: 'g1'),
      fakeQueue('c', name: 'Gama', groupId: 'g2'),
      fakeQueue('d', name: 'Delta', groupId: 'g2'),
      fakeQueue('e', name: 'Epsilon'),
      fakeQueue('f', name: 'Zeta'),
    ];

    testWidgets('hides groups without results and expands the others', (
      tester,
    ) async {
      final store = MemoryCollapseStore({'g1'});
      await pumpTall(
        tester,
        homeWith(
          queues: many(),
          groups: _groups,
          store: store,
          waiting: {'a': 2, 'b': 3},
        ),
      );
      await tick(tester);
      expect(find.text('Alfa'), findsNothing);

      await tester.enterText(find.byType(TextField), 'alf');
      await tick(tester);
      expect(find.text('Alfa'), findsOneWidget);
      expect(find.text('Loja Centro'), findsOneWidget);
      expect(find.text('1 fila · 2 esperando'), findsOneWidget);
      expect(find.text('Anexo'), findsNothing);
      expect(find.text('Sem grupo'), findsNothing);
      expect(find.text('Beta'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tick(tester);
      expect(find.text('Nenhuma fila encontrada'), findsOneWidget);
      expect(store.saved, {'g1'});
    });

    testWidgets('sorting applies inside each group', (tester) async {
      await pumpTall(
        tester,
        homeWith(queues: many(), groups: _groups, waiting: {'a': 1, 'b': 9}),
      );
      await tick(tester);
      expect(
        tester.getTopLeft(find.text('Alfa')).dy,
        lessThan(tester.getTopLeft(find.text('Beta')).dy),
      );
    });
  });

  testWidgets('operator section stays flat and unfiltered', (tester) async {
    final op = fakeQueue('o1', name: 'Banco', groupId: 'g1');
    await pumpTall(
      tester,
      homeWith(
        queues: _sample(),
        groups: _groups,
        extra: {'o1': op},
        operating: [
          QueueOperator(uid: 'uid-1', queueId: 'o1', queueName: 'Banco'),
        ],
        store: MemoryCollapseStore({'g1', 'g2', ungroupedSectionId}),
      ),
    );
    await tick(tester);
    expect(find.text('SOU OPERADOR'), findsOneWidget);
    expect(find.text('Banco'), findsOneWidget);
    expect(find.text('Você é operador desta fila'), findsOneWidget);
  });

  testWidgets('header exposes button, expanded state and spoken label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpTall(
      tester,
      homeWith(
        queues: _sample(),
        groups: _groups,
        waiting: {'a': 5, 'b': 4, 'c': 3},
      ),
    );
    await tick(tester);
    final finder = find.bySemanticsLabel(
      'Loja Centro, 3 filas, 12 esperando, expandido',
    );
    expect(finder, findsOneWidget);
    expect(
      tester.getSemantics(finder),
      isSemantics(isButton: true, hasExpandedState: true, isExpanded: true),
    );
    expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));

    await tester.tap(find.text('Loja Centro'));
    await tick(tester);
    expect(
      find.bySemanticsLabel('Loja Centro, 3 filas, 12 esperando, recolhido'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('english labels', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTall(
      tester,
      homeWith(queues: _sample(), groups: _groups, waiting: {'d': 1}),
      locale: const Locale('en'),
    );
    await tick(tester);
    expect(find.text('1 queue · 1 waiting'), findsOneWidget);
    expect(find.text('No group'), findsOneWidget);
    handle.dispose();
  });

  for (final width in [320.0, 900.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('no overflow at $width px and ${scale}x text', (
        tester,
      ) async {
        await pumpTall(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: homeWith(
                queues: _sample(),
                groups: [qg('g1', 'Loja Centro de Distribuicao Grande')],
                waiting: {'a': 120, 'b': 4},
              ),
            ),
          ),
          size: Size(width, 3000),
        );
        await tick(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Sem grupo'), findsOneWidget);
      });
    }
  }
}
