import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_group.dart';
import 'package:qio_app/screens/groups_screen.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

QueueGroup g(String id, String name, {int? order, String? color}) => QueueGroup(
  id: id,
  name: name,
  createdAt: DateTime(2026),
  order: order,
  colorHex: color,
);

Future<FakeGroupService> pumpGroups(
  WidgetTester tester,
  List<QueueGroup> groups,
) async {
  final svc = FakeGroupService(groups: groups);
  await pumpApp(
    tester,
    GroupsScreen(groups: svc, queues: FakeQueueService()),
    size: const Size(390, 900),
  );
  await tester.pump();
  await tester.pump();
  return svc;
}

int customActionId(String label) =>
    CustomSemanticsAction.getIdentifier(CustomSemanticsAction(label: label));

void main() {
  testWidgets('ação semântica Mover para baixo grava a nova ordem', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final svc = await pumpGroups(tester, [
      g('a', 'Alfa', order: 0),
      g('b', 'Beta', order: 1),
      g('c', 'Gama', order: 2),
    ]);
    final node = tester.getSemantics(find.byKey(const ValueKey('group-row-a')));
    final data = node.getSemanticsData();
    expect(data.customSemanticsActionIds, isNotNull);
    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      customActionId('Mover para baixo'),
    );
    await tester.pump();
    expect(svc.calls, contains('reorderGroups:b,a,c'));
    handle.dispose();
  });

  testWidgets('ação semântica Mover para cima no último grupo', (tester) async {
    final handle = tester.ensureSemantics();
    final svc = await pumpGroups(tester, [
      g('a', 'Alfa', order: 0),
      g('b', 'Beta', order: 1),
    ]);
    final node = tester.getSemantics(find.byKey(const ValueKey('group-row-b')));
    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      customActionId('Mover para cima'),
    );
    await tester.pump();
    expect(svc.calls, contains('reorderGroups:b,a'));
    handle.dispose();
  });

  testWidgets('escolher cor grava colorHex e Sem cor remove', (tester) async {
    final svc = await pumpGroups(tester, [g('a', 'Alfa', color: '#2563EB')]);
    await tester.tap(find.byTooltip('Cor do grupo "Alfa"'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('#0F766E'));
    await tester.pumpAndSettle();
    expect(svc.calls, ['updateGroupColor:a:#0F766E']);

    await tester.tap(find.byTooltip('Cor do grupo "Alfa"'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-color-none')));
    await tester.pumpAndSettle();
    expect(svc.calls.last, 'updateGroupColor:a:null');
  });

  testWidgets('mesma cor não grava', (tester) async {
    final svc = await pumpGroups(tester, [g('a', 'Alfa', color: '#2563EB')]);
    await tester.tap(find.byTooltip('Cor do grupo "Alfa"'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('#2563EB'));
    await tester.pumpAndSettle();
    expect(svc.calls, isEmpty);
  });
}
