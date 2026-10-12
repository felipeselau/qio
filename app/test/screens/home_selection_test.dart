import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/operator.dart';
import 'package:qio_app/models/queue_group.dart';
import 'package:qio_app/screens/home_screen.dart';
import 'package:qio_app/services/group_service.dart';

import '../helpers/fake_auth.dart';
import '../helpers/fake_collapse_store.dart';
import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

QueueGroup qg(String id, String name) =>
    QueueGroup(id: id, name: name, createdAt: DateTime(2025, 1, 1));

Future<FakeGroupService> pumpHome(
  WidgetTester tester, {
  List<QueueOperator> operating = const [],
}) async {
  final groups = FakeGroupService(
    groups: [qg('g1', 'Loja Centro'), qg('g2', 'Anexo')],
  );
  await pumpApp(
    tester,
    HomeScreen(
      auth: FakeAuthService(user: FakeUser(displayName: 'Maria')),
      queues: FakeQueueService(
        ownerQueues: [
          fakeQueue('a', name: 'Caixa 1', groupId: 'g1'),
          fakeQueue('b', name: 'Caixa 2'),
          fakeQueue('c', name: 'Caixa 3'),
        ],
      ),
      operators: FakeOperatorService(operating: operating),
      groups: groups,
      collapseStore: MemoryCollapseStore(),
      enableIntegrations: false,
    ),
    size: const Size(390, 2400),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  return groups;
}

void main() {
  testWidgets('long press enters selection with the card selected', (
    tester,
  ) async {
    await pumpHome(tester);
    await tester.longPress(find.text('Caixa 2'));
    await tester.pump();
    expect(find.text('1 fila selecionada'), findsWidgets);
    expect(find.byType(Checkbox), findsNWidgets(3));
    expect(
      tester.widgetList<Checkbox>(find.byType(Checkbox)).where((c) => c.value!),
      hasLength(1),
    );
    expect(find.byType(FloatingActionButton).hitTestable(), findsNothing);
  });

  testWidgets('select action, toggling and counter', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byTooltip('Selecionar filas'));
    await tester.pump();
    expect(find.text('Nenhuma fila selecionada'), findsWidgets);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('selection-move')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Caixa 1'));
    await tester.tap(find.text('Caixa 3'));
    await tester.pump();
    expect(find.text('2 filas selecionadas'), findsWidgets);
    await tester.tap(find.text('Caixa 3'));
    await tester.pump();
    expect(find.text('1 fila selecionada'), findsWidgets);
  });

  testWidgets('selected state is exposed to accessibility', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester);
    await tester.tap(find.byTooltip('Selecionar filas'));
    await tester.pump();
    await tester.tap(find.text('Caixa 1'));
    await tester.pump();
    final finder = find.bySemanticsLabel(RegExp('Selecionar a fila Caixa 1'));
    expect(finder, findsOneWidget);
    final data = tester.getSemantics(finder).getSemanticsData();
    expect(data.flagsCollection.isChecked.name, 'isTrue');
    handle.dispose();
  });

  testWidgets('system back leaves selection before leaving home', (
    tester,
  ) async {
    await pumpHome(tester);
    await tester.longPress(find.text('Caixa 2'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('Caixa 2'), findsOneWidget);
    await tester.longPress(find.text('Caixa 2'));
    await tester.pump();
    await tester.tap(find.byTooltip('Sair da seleção'));
    await tester.pump();
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('move to an existing group and exit the mode', (tester) async {
    final groups = await pumpHome(tester);
    await tester.tap(find.byTooltip('Selecionar filas'));
    await tester.pump();
    await tester.tap(find.text('Caixa 2'));
    await tester.tap(find.text('Caixa 3'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('selection-move')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('move-target-g2')));
    await tester.pumpAndSettle();
    expect(groups.calls, contains('setQueuesGroup:b,c:g2'));
    expect(find.text('2 filas movidas para "Anexo"'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('Sem grupo sends null', (tester) async {
    final groups = await pumpHome(tester);
    await tester.longPress(find.text('Caixa 1'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('selection-move')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('move-target-none')));
    await tester.pumpAndSettle();
    expect(groups.calls, contains('setQueuesGroup:a:null'));
  });

  testWidgets('new group is created then used', (tester) async {
    final groups = await pumpHome(tester);
    await tester.longPress(find.text('Caixa 2'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('selection-move')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('move-target-new')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextFormField), 'Filial');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(groups.calls, ['createGroup:Filial', 'setQueuesGroup:b:new']);
  });

  testWidgets('partial failure is reported and selection stays', (
    tester,
  ) async {
    final groups = await pumpHome(tester);
    groups.moveResult = const GroupBatchResult(total: 2, updated: 1);
    await tester.tap(find.byTooltip('Selecionar filas'));
    await tester.pump();
    await tester.tap(find.text('Caixa 2'));
    await tester.tap(find.text('Caixa 3'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('selection-move')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('move-target-g1')));
    await tester.pumpAndSettle();
    expect(
      find.text('1 de 2 filas movidas. Tente de novo para as demais.'),
      findsOneWidget,
    );
    expect(find.byType(Checkbox), findsNWidgets(3));
  });

  testWidgets('operator queues are not selectable', (tester) async {
    await pumpHome(
      tester,
      operating: [
        QueueOperator(queueId: 'op1', queueName: 'Da Ana', uid: 'u1'),
      ],
    );
    await tester.tap(find.byTooltip('Selecionar filas'));
    await tester.pump();
    expect(find.byType(Checkbox), findsNWidgets(3));
  });
}
