import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/operator.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/screens/home_screen.dart';
import 'package:qio_app/screens/join_operator_screen.dart';
import 'package:qio_app/services/home_prompts.dart';

import '../helpers/fake_auth.dart';
import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

HomeScreen home({FakeQueueService? queues, FakeOperatorService? operators}) =>
    HomeScreen(
      auth: FakeAuthService(user: FakeUser(displayName: 'Maria')),
      queues: queues ?? FakeQueueService(),
      operators: operators ?? FakeOperatorService(),
      enableIntegrations: false,
    );

class _Recorder {
  final events = <String>[];
  bool pushWanted = true;
  bool dialogOpen = false;
  Completer<void>? tourGate;

  HomePrompts build() => HomePrompts(
    runTour: () async {
      events.add('tour:start');
      await tourGate?.future;
      events.add('tour:end');
    },
    shouldPromptPush: () async => pushWanted,
    askPush: () async => events.add('push'),
    canShowDialog: () => !dialogOpen,
  );
}

HomeScreen homeWithPrompts(FakeQueueService queues, HomePrompts prompts) =>
    HomeScreen(
      auth: FakeAuthService(user: FakeUser(displayName: 'Maria')),
      queues: queues,
      operators: FakeOperatorService(),
      enableIntegrations: false,
      prompts: prompts,
    );

void main() {
  testWidgets('shows skeleton before the first emission', (tester) async {
    await pumpApp(tester, home());
    expect(find.text('Minhas filas'), findsOneWidget);
    expect(find.text('Nenhuma fila ainda'), findsNothing);
    await tick(tester);
  });

  testWidgets('empty state when there are no queues', (tester) async {
    await pumpApp(tester, home());
    await tick(tester);
    expect(find.text('Nenhuma fila ainda'), findsOneWidget);
    expect(find.text('SOU DONO'), findsNothing);
  });

  testWidgets('lists owned queues with status and waiting count', (
    tester,
  ) async {
    final queues = FakeQueueService(
      ownerQueues: [
        fakeQueue('a', name: 'Padaria'),
        fakeQueue('b', name: 'Clinica', status: QueueStatus.paused),
      ],
      waitingCounts: {'a': 3, 'b': 1},
    );
    await pumpApp(tester, home(queues: queues));
    await tick(tester);
    expect(find.text('Padaria'), findsOneWidget);
    expect(find.text('Clinica'), findsOneWidget);
    expect(find.text('3 pessoas esperando'), findsOneWidget);
    expect(find.text('1 pessoa esperando'), findsOneWidget);
    expect(find.text('Aberta'), findsOneWidget);
    expect(find.text('Pausada'), findsOneWidget);
    expect(find.text('SOU DONO'), findsNothing);
  });

  testWidgets('shows owner and operator sections together', (tester) async {
    final queues = FakeQueueService(
      ownerQueues: [fakeQueue('a', name: 'Padaria')],
      queues: {'o1': fakeQueue('o1', name: 'Banco')},
    );
    final operators = FakeOperatorService(
      operating: [
        QueueOperator(uid: 'uid-1', queueId: 'o1', queueName: 'Banco'),
      ],
    );
    await pumpApp(tester, home(queues: queues, operators: operators));
    await tick(tester);
    expect(find.text('SOU DONO'), findsOneWidget);
    expect(find.text('SOU OPERADOR'), findsOneWidget);
    expect(find.text('Padaria'), findsOneWidget);
    expect(find.text('Banco'), findsOneWidget);
    expect(find.text('Você é operador desta fila'), findsOneWidget);
  });

  testWidgets('operator-only user sees the operator section', (tester) async {
    final queues = FakeQueueService(
      queues: {'o1': fakeQueue('o1', name: 'Banco')},
    );
    final operators = FakeOperatorService(
      operating: [
        QueueOperator(uid: 'uid-1', queueId: 'o1', queueName: 'Banco'),
      ],
    );
    await pumpApp(tester, home(queues: queues, operators: operators));
    await tick(tester);
    expect(find.text('SOU OPERADOR'), findsOneWidget);
    expect(find.text('SOU DONO'), findsNothing);
    expect(find.text('Nenhuma fila ainda'), findsNothing);
  });

  testWidgets('pending and rejected operator requests are listed', (
    tester,
  ) async {
    final operators = FakeOperatorService(
      requests: [
        OperatorRequest(
          uid: 'uid-1',
          queueId: 'p1',
          queueName: 'Mercado',
          status: OperatorRequestStatus.pending,
        ),
        OperatorRequest(
          uid: 'uid-1',
          queueId: 'p2',
          queueName: 'Loja',
          status: OperatorRequestStatus.rejected,
        ),
      ],
    );
    await pumpApp(tester, home(operators: operators));
    await tick(tester);
    expect(find.text('PEDIDOS DE OPERADOR'), findsOneWidget);
    expect(find.text('Aguardando aprovação'), findsOneWidget);
    expect(find.text('Pedido recusado'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tick(tester);
    expect(operators.calls, ['cancel:p2']);
  });

  testWidgets('shows retry state when the owner stream errors', (tester) async {
    final queues = FakeQueueService()..ownerQueuesError = Exception('x');
    await pumpApp(tester, home(queues: queues));
    await tick(tester);
    expect(find.text('Nenhuma fila ainda'), findsNothing);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('renders in English dark at 320 width', (tester) async {
    final queues = FakeQueueService(
      ownerQueues: [fakeQueue('a', name: 'Bakery')],
      waitingCounts: {'a': 2},
    );
    await pumpApp(
      tester,
      home(queues: queues),
      locale: const Locale('en'),
      themeMode: ThemeMode.dark,
      size: const Size(320, 640),
    );
    await tick(tester);
    expect(find.text('My queues'), findsOneWidget);
    expect(find.text('Bakery'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app bar no longer has the operator shortcut', (tester) async {
    await pumpApp(
      tester,
      home(queues: FakeQueueService(ownerQueues: [fakeQueue('a')])),
    );
    await tick(tester);
    expect(find.byTooltip('Entrar como operador'), findsNothing);
    expect(find.byTooltip('Grupos'), findsOneWidget);
    expect(find.byTooltip('Métricas das filas'), findsOneWidget);
    expect(find.byTooltip('Minha conta'), findsOneWidget);
  });

  testWidgets('account menu offers account and join as operator', (
    tester,
  ) async {
    await pumpApp(tester, home());
    await tick(tester);
    final size = tester.getSize(find.byTooltip('Minha conta'));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byTooltip('Minha conta'));
    await tick(tester);
    expect(find.text('Minha conta'), findsOneWidget);
    await tester.tap(find.text('Entrar como operador').last);
    await tick(tester);
    expect(find.byType(JoinOperatorScreen), findsOneWidget);
  });

  testWidgets('empty state links to join as operator', (tester) async {
    await pumpApp(tester, home());
    await tick(tester);
    await tester.tap(find.text('Entrar como operador'));
    await tick(tester);
    expect(find.byType(JoinOperatorScreen), findsOneWidget);
  });

  group('startup prompts', () {
    testWidgets('tour runs first and push waits for it', (tester) async {
      final rec = _Recorder()..tourGate = Completer<void>();
      final queues = FakeQueueService(ownerQueues: [fakeQueue('a')]);
      await pumpApp(tester, homeWithPrompts(queues, rec.build()));
      await tick(tester);
      expect(rec.events, ['tour:start']);
      rec.tourGate!.complete();
      await tick(tester);
      expect(rec.events, ['tour:start', 'tour:end', 'push']);
    });

    testWidgets('push is not asked before the first queue exists', (
      tester,
    ) async {
      final rec = _Recorder();
      await pumpApp(tester, homeWithPrompts(FakeQueueService(), rec.build()));
      await tick(tester);
      expect(rec.events, ['tour:start', 'tour:end']);
    });

    testWidgets('push is skipped while another dialog is open', (tester) async {
      final rec = _Recorder()..dialogOpen = true;
      final queues = FakeQueueService(ownerQueues: [fakeQueue('a')]);
      await pumpApp(tester, homeWithPrompts(queues, rec.build()));
      await tick(tester);
      expect(rec.events, ['tour:start', 'tour:end']);
    });

    testWidgets('push is not asked when already decided', (tester) async {
      final rec = _Recorder()..pushWanted = false;
      final queues = FakeQueueService(ownerQueues: [fakeQueue('a')]);
      await pumpApp(tester, homeWithPrompts(queues, rec.build()));
      await tick(tester);
      expect(rec.events, ['tour:start', 'tour:end']);
    });
  });
}
