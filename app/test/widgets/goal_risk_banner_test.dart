import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_goals.dart';
import 'package:qio_app/screens/home_screen.dart';
import 'package:qio_app/screens/queue_panel_screen.dart';
import 'package:qio_app/widgets/queue_panel/goal_risk_banner.dart';

import '../helpers/fake_auth.dart';
import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

const tall = Size(390, 2600);
const goals = QueueGoals(maxWaitMin: 30);

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

QueuePanelScreen panel(FakeQueueService queues, {bool isOwner = true}) =>
    QueuePanelScreen(
      queueId: 'q1',
      queueName: 'Padaria',
      isOwner: isOwner,
      queues: queues,
      operators: FakeOperatorService(),
      groups: FakeGroupService(),
      showTour: false,
    );

FakeQueueService service(int waiting, {QueueGoals? g = goals, int avg = 10}) =>
    FakeQueueService(
      queues: {
        'q1': fakeQueue('q1', name: 'Padaria', goals: g, avgServiceMin: avg),
      },
      entries: {
        'q1': [
          for (var i = 1; i <= waiting; i++) fakeEntry('e$i', i, name: 'P$i'),
        ],
      },
    );

Finder get banner => find.byKey(const ValueKey('goal-risk-banner'));

void main() {
  group('painel', () {
    testWidgets('mostra o banner quando a espera estimada passa da meta', (
      tester,
    ) async {
      await pumpApp(tester, panel(service(4)), size: tall);
      await tick(tester);
      expect(banner, findsOneWidget);
      expect(find.text('Meta de espera em risco'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('goal-risk-body'))).data,
        'Com 4 na fila, a espera estimada é de 40 min, acima da meta de 30 min.',
      );
      expect(
        find.text('Sugestão: chame mais um atendente ou abra outro balcão.'),
        findsOneWidget,
      );
    });

    testWidgets('exatamente na meta não mostra', (tester) async {
      await pumpApp(tester, panel(service(3)), size: tall);
      await tick(tester);
      expect(banner, findsNothing);
    });

    testWidgets('sem meta de espera não mostra', (tester) async {
      await pumpApp(tester, panel(service(9, g: null)), size: tall);
      await tick(tester);
      expect(banner, findsNothing);
      await pumpApp(
        tester,
        panel(service(9, g: const QueueGoals(maxServiceMin: 5))),
        size: tall,
      );
      await tick(tester);
      expect(banner, findsNothing);
    });

    testWidgets('operador também vê o banner', (tester) async {
      await pumpApp(tester, panel(service(5), isOwner: false), size: tall);
      await tick(tester);
      expect(banner, findsOneWidget);
    });

    testWidgets('estimativa automática substitui o tempo manual', (
      tester,
    ) async {
      final q = service(4)..avgAuto = 5;
      await pumpApp(tester, panel(q), size: tall);
      await tick(tester);
      expect(banner, findsNothing);
      q.avgAutoControllers['q1']!.add(12);
      await tick(tester);
      expect(banner, findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('goal-risk-body'))).data,
        contains('48 min'),
      );
    });

    testWidgets('fila vazia não mostra', (tester) async {
      final q = FakeQueueService(
        queues: {'q1': fakeQueue('q1', goals: goals)},
        entries: {'q1': const []},
      );
      await pumpApp(tester, panel(q), size: tall);
      await tick(tester);
      expect(banner, findsNothing);
    });
  });

  group('banner isolado', () {
    testWidgets('troca de meta liga e desliga o banner', (tester) async {
      final q = FakeQueueService();
      final notifier = ValueNotifier<QueueGoals?>(null);
      addTearDown(notifier.dispose);
      await pumpApp(
        tester,
        Scaffold(
          body: ValueListenableBuilder<QueueGoals?>(
            valueListenable: notifier,
            builder: (_, g, _) => GoalRiskBanner(
              queueId: 'q1',
              goals: g,
              waiting: 10,
              manualAvgMin: 10,
              queues: q,
            ),
          ),
        ),
      );
      expect(banner, findsNothing);
      notifier.value = goals;
      await tick(tester);
      expect(banner, findsOneWidget);
      notifier.value = null;
      await tick(tester);
      expect(banner, findsNothing);
    });
  });

  group('home', () {
    HomeScreen home(FakeQueueService queues) => HomeScreen(
      auth: FakeAuthService(user: FakeUser(displayName: 'Maria')),
      queues: queues,
      operators: FakeOperatorService(),
      enableIntegrations: false,
    );

    testWidgets('selo discreto no card quando a espera passa da meta', (
      tester,
    ) async {
      final queues = FakeQueueService(
        ownerQueues: [
          fakeQueue('a', name: 'Padaria', goals: goals),
          fakeQueue('b', name: 'Clinica', goals: goals),
          fakeQueue('c', name: 'Banco'),
        ],
        waitingCounts: {'a': 4, 'b': 3, 'c': 50},
      );
      await pumpApp(tester, home(queues));
      await tick(tester);
      expect(find.byKey(const ValueKey('goal-risk-badge-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('goal-risk-badge-b')), findsNothing);
      expect(find.byKey(const ValueKey('goal-risk-badge-c')), findsNothing);
      expect(find.text('Meta de espera em risco'), findsOneWidget);
    });

    testWidgets('selo usa o tempo médio manual da fila', (tester) async {
      final queues = FakeQueueService(
        ownerQueues: [
          fakeQueue('a', name: 'Padaria', goals: goals, avgServiceMin: 5),
        ],
        waitingCounts: {'a': 6},
      );
      await pumpApp(tester, home(queues));
      await tick(tester);
      expect(find.byKey(const ValueKey('goal-risk-badge-a')), findsNothing);
    });
  });
}
