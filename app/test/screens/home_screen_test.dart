import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/operator.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/screens/home_screen.dart';

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
}
