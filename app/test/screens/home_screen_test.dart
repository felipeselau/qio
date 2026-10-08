import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/operator.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/screens/home_screen.dart';
import 'package:qio_app/screens/join_operator_screen.dart';
import 'package:qio_app/screens/qr_poster_screen.dart';
import 'package:qio_app/services/home_prompts.dart';
import 'package:qio_app/services/queue_sort.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('search and sort', () {
    FakeQueueService many() => FakeQueueService(
      ownerQueues: [
        for (final n in ['Zeta', 'Alfa', 'Beta', 'Gama', 'Delta', 'Epsilon'])
          fakeQueue(n, name: n),
      ],
      waitingCounts: {'Zeta': 9},
    );

    testWidgets('tools hidden with five queues or fewer', (tester) async {
      final queues = FakeQueueService(
        ownerQueues: [
          for (final n in ['A', 'B', 'C', 'D', 'E']) fakeQueue(n, name: n),
        ],
      );
      await pumpApp(tester, home(queues: queues));
      await tick(tester);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('search filters and shows empty message', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester, home(queues: many()));
      await tick(tester);
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'alf');
      await tick(tester);
      expect(find.text('Alfa'), findsOneWidget);
      expect(find.text('Zeta'), findsNothing);
      await tester.enterText(find.byType(TextField), 'xyz');
      await tick(tester);
      expect(find.text('Nenhuma fila encontrada'), findsOneWidget);
    });

    testWidgets('sort by longest wait puts the busiest first and persists', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester, home(queues: many()));
      await tick(tester);
      expect(
        tester.getTopLeft(find.text('Alfa')).dy,
        lessThan(tester.getTopLeft(find.text('Beta')).dy),
      );
      await tester.tap(find.byTooltip('Ordenar filas'));
      await tick(tester);
      await tester.tap(find.text('Mais espera'));
      await tick(tester);
      expect(
        tester.getTopLeft(find.text('Zeta')).dy,
        lessThan(tester.getTopLeft(find.text('Alfa')).dy),
      );
      expect(await QueueSortPrefs.load(), QueueSort.waiting);
    });

    testWidgets('saved waiting sort is applied after prefs load', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({QueueSortPrefs.key: 'waiting'});
      await pumpApp(tester, home(queues: many()));
      await tick(tester);
      expect(
        tester.getTopLeft(find.text('Zeta')).dy,
        lessThan(tester.getTopLeft(find.text('Alfa')).dy),
      );
    });

    testWidgets('clear button resets the search', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester, home(queues: many()));
      await tick(tester);
      expect(find.byTooltip('Limpar'), findsNothing);
      await tester.enterText(find.byType(TextField), 'alf');
      await tick(tester);
      await tester.tap(find.byTooltip('Limpar'));
      await tick(tester);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('one waiting-count subscription per queue, cancelled on exit', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({QueueSortPrefs.key: 'waiting'});
      final queues = many();
      await pumpApp(tester, home(queues: queues));
      await tick(tester);
      expect(queues.waitingListens.values.every((v) => v == 1), isTrue);
      expect(queues.waitingListens.length, 6);
      await tester.enterText(find.byType(TextField), 'alf');
      await tick(tester);
      await tester.tap(find.byTooltip('Ordenar filas'));
      await tick(tester);
      await tester.tap(find.text('Nome'));
      await tick(tester);
      expect(queues.waitingListens.values.every((v) => v == 1), isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(queues.waitingListens.values.every((v) => v == 0), isTrue);
    });

    testWidgets('sort button meets the tap target size', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester, home(queues: many()));
      await tick(tester);
      final size = tester.getSize(find.byTooltip('Ordenar filas'));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('quick actions', () {
    FakeQueueService svc({QueueStatus status = QueueStatus.open}) =>
        FakeQueueService(
          ownerQueues: [fakeQueue('a', name: 'Padaria', status: status)],
        );

    testWidgets('pause asks for a message and then updates the status', (
      tester,
    ) async {
      final queues = svc();
      await pumpApp(tester, home(queues: queues));
      await tick(tester);
      await tester.tap(find.bySemanticsLabel('Pausar fila Padaria'));
      await tester.pumpAndSettle();
      expect(queues.calls.where((c) => c.startsWith('status')), isEmpty);
      await tester.enterText(find.byType(TextField), 'Volto logo');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Pausar'),
        ),
      );
      await tester.pumpAndSettle();
      expect(queues.calls, contains('status:a:paused'));
      expect(queues.lastStatusMessage, 'Volto logo');
    });

    testWidgets('cancelling the pause dialog changes nothing', (tester) async {
      final queues = svc();
      await pumpApp(tester, home(queues: queues));
      await tick(tester);
      await tester.tap(find.bySemanticsLabel('Pausar fila Padaria'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(queues.calls.where((c) => c.startsWith('status')), isEmpty);
    });

    testWidgets('reopen a paused queue is direct', (tester) async {
      final queues = svc(status: QueueStatus.paused);
      await pumpApp(tester, home(queues: queues));
      await tick(tester);
      await tester.tap(find.bySemanticsLabel('Reabrir fila Padaria'));
      await tester.pumpAndSettle();
      expect(queues.calls, contains('status:a:open'));
    });

    testWidgets('failure shows the described error', (tester) async {
      final queues = svc(status: QueueStatus.closed)
        ..statusError = TimeoutException('x');
      await pumpApp(tester, home(queues: queues));
      await tick(tester);
      await tester.tap(find.bySemanticsLabel('Reabrir fila Padaria'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Sem conexão. Verifique a internet e tente novamente.'),
        findsOneWidget,
      );
    });

    testWidgets('qr action opens the poster screen', (tester) async {
      await pumpApp(tester, home(queues: svc()));
      await tick(tester);
      await tester.tap(
        find.bySemanticsLabel('Mostrar QR code da fila Padaria'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QrPosterScreen), findsOneWidget);
    });

    testWidgets('quick actions meet tap target and label guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, home(queues: svc()));
      await tick(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('operator cards have no quick actions', (tester) async {
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
      expect(find.text('Pausar'), findsNothing);
      expect(find.text('QR code'), findsNothing);
    });
  });

  testWidgets('app bar fits 320dp with 1.5 text scale in pt', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: home(queues: FakeQueueService(ownerQueues: [fakeQueue('a')])),
        ),
      ),
      size: const Size(320, 640),
    );
    await tick(tester);
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Minha conta'), findsOneWidget);
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

    testWidgets('nothing is shown while another dialog is open', (
      tester,
    ) async {
      final rec = _Recorder()..dialogOpen = true;
      final queues = FakeQueueService(ownerQueues: [fakeQueue('a')]);
      await pumpApp(tester, homeWithPrompts(queues, rec.build()));
      await tick(tester);
      expect(rec.events, isEmpty);
    });

    testWidgets('tour and push wait until the home route is current again', (
      tester,
    ) async {
      final rec = _Recorder();
      final queues = FakeQueueService(ownerQueues: [fakeQueue('a')]);
      await pumpApp(tester, homeWithPrompts(queues, rec.build()));
      final navigator = Navigator.of(tester.element(find.byType(HomeScreen)));
      navigator.push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
      await tick(tester);
      expect(rec.events, isEmpty);
      navigator.pop();
      await tick(tester);
      expect(rec.events, ['tour:start', 'tour:end', 'push']);
    });

    testWidgets('push asked after returning from the first queue creation', (
      tester,
    ) async {
      final rec = _Recorder();
      final queues = FakeQueueService();
      await pumpApp(tester, homeWithPrompts(queues, rec.build()));
      await tick(tester);
      expect(rec.events, ['tour:start', 'tour:end']);
      final navigator = Navigator.of(tester.element(find.byType(HomeScreen)));
      navigator.push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
      await tick(tester);
      queues.emitOwnerQueues([fakeQueue('a')]);
      await tick(tester);
      expect(rec.events, ['tour:start', 'tour:end']);
      navigator.pop();
      await tick(tester);
      expect(rec.events, ['tour:start', 'tour:end', 'push']);
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
