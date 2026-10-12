import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/alerts_config.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/services/group_service.dart';

import '../helpers/fake_services.dart';
import 'home_grouped_test.dart' show homeWith, pumpTall, qg, tick;

const _menuTip = 'Ações em lote do grupo Loja Centro';

List<Queue> _sample() => [
  fakeQueue('a', name: 'Caixa 1', groupId: 'g1'),
  fakeQueue(
    'b',
    name: 'Caixa 2',
    groupId: 'g1',
    alerts: const AlertsConfig(enabled: true, maxWaitMin: 45),
  ),
  fakeQueue('d', name: 'Balcao', groupId: 'g2'),
];

Future<FakeQueueService> pumpHome(WidgetTester tester) async {
  final home = homeWith(
    queues: _sample(),
    groups: [qg('g1', 'Loja Centro'), qg('g2', 'Anexo')],
  );
  await pumpTall(tester, home);
  await tick(tester);
  return home.queues! as FakeQueueService;
}

Future<void> openDialog(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_menuTip));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('group-apply-alerts')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('menu offers apply alerts and prefills from the group', (
    tester,
  ) async {
    await pumpHome(tester);
    await openDialog(tester);
    expect(find.text('Alertas do grupo "Loja Centro"'), findsOneWidget);
    final sw = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('alerts-enabled')),
    );
    expect(sw.value, isTrue);
    expect(find.text('45 min'), findsWidgets);
  });

  testWidgets('confirm shows the count and applies the config', (tester) async {
    final queues = await pumpHome(tester);
    await openDialog(tester);
    await tester.tap(find.byKey(const ValueKey('group-alerts-continue')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('2 filas do grupo "Loja Centro"'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('group-alerts-apply')));
    await tester.pumpAndSettle();
    expect(queues.calls, contains('groupAlerts:g1'));
    expect(queues.lastGroupAlerts!.maxWaitMin, 45);
    expect(find.text('Alertas aplicados a 2 filas'), findsOneWidget);
  });

  testWidgets('cancel at confirmation writes nothing', (tester) async {
    final queues = await pumpHome(tester);
    await openDialog(tester);
    await tester.tap(find.byKey(const ValueKey('group-alerts-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(queues.calls.where((c) => c.startsWith('groupAlerts')), isEmpty);
  });

  testWidgets('invalid config disables continue', (tester) async {
    await pumpHome(tester);
    await openDialog(tester);
    await tester.tap(find.byKey(const ValueKey('alerts-wait')));
    await tester.pumpAndSettle();
    final btn = tester.widget<TextButton>(
      find.byKey(const ValueKey('group-alerts-continue')),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('partial failure is reported', (tester) async {
    final queues = await pumpHome(tester);
    queues.groupAlertsResult = const GroupBatchResult(total: 5, updated: 3);
    await openDialog(tester);
    await tester.tap(find.byKey(const ValueKey('group-alerts-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-alerts-apply')));
    await tester.pumpAndSettle();
    expect(
      find.text('3 de 5 atualizadas. Tente de novo para as demais.'),
      findsOneWidget,
    );
  });
}
