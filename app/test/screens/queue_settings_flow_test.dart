import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_entry.dart';
import 'package:qio_app/screens/queue_panel_screen.dart';
import 'package:qio_app/screens/queue_settings_screen.dart';
import 'package:qio_app/widgets/queue_panel/alerts_tile.dart';
import 'package:qio_app/widgets/queue_panel/current_called_card.dart';
import 'package:qio_app/widgets/queue_panel/operators_tile.dart';
import 'package:qio_app/widgets/queue_panel/panel_notices.dart';
import 'package:qio_app/widgets/queue_panel/queue_qr_card.dart';
import 'package:qio_app/widgets/queue_panel/waiting_tile.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

class Home extends StatelessWidget {
  const Home({super.key, required this.panel});

  final Widget panel;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => panel)),
        child: const Text('abrir'),
      ),
    ),
  );
}

FakeQueueService service({QueueStatus status = QueueStatus.open}) =>
    FakeQueueService(
      queues: {'q1': fakeQueue('q1', name: 'Padaria', status: status)},
      entries: {
        'q1': [
          fakeEntry('e1', 1, name: 'Ana', status: EntryStatus.called),
          fakeEntry('e2', 2, name: 'Bruno'),
        ],
      },
    );

QueuePanelScreen panel(
  FakeQueueService queues, {
  bool isOwner = true,
  FakeOperatorService? operators,
}) => QueuePanelScreen(
  queueId: 'q1',
  queueName: 'Padaria',
  isOwner: isOwner,
  queues: queues,
  operators: operators ?? FakeOperatorService(),
  groups: FakeGroupService(),
  showTour: false,
);

Future<void> openFromHome(WidgetTester tester, Widget p, Size size) async {
  await pumpApp(tester, Home(panel: p), size: size);
  await tester.tap(find.text('abrir'));
  await tick(tester);
}

void main() {
  testWidgets('operator losing access with settings open returns home', (
    tester,
  ) async {
    final ops = FakeOperatorService();
    await openFromHome(
      tester,
      panel(service(), isOwner: false, operators: ops),
      const Size(390, 844),
    );
    await tester.tap(find.byTooltip('QR code da fila'));
    await tick(tester);
    expect(find.byType(QueueSettingsScreen), findsOneWidget);
    expect(find.text('QR code'), findsOneWidget);
    ops.access.add(false);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Acesso encerrado'), findsOneWidget);
    expect(find.byType(QueueSettingsScreen), findsNothing);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanelScreen), findsNothing);
    expect(find.byType(QueueSettingsScreen), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('queue deleted elsewhere closes settings with a notice', (
    tester,
  ) async {
    final exists = StreamController<bool>.broadcast();
    addTearDown(exists.close);
    final queues = service()..existsOverride = exists.stream;
    await openFromHome(tester, panel(queues), const Size(390, 844));
    await tester.tap(find.byTooltip('Configurações da fila'));
    await tick(tester);
    expect(find.byType(QueueSettingsScreen), findsOneWidget);
    exists.add(false);
    await tick(tester);
    await tick(tester);
    await tick(tester);
    expect(find.byType(QueueSettingsScreen), findsNothing);
    expect(find.text('Esta fila não existe mais'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanelScreen), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('settings closes with a notice when the exists stream fails', (
    tester,
  ) async {
    final queues = service()
      ..existsOverride = Stream<bool>.error(Exception('x'));
    await openFromHome(tester, panel(queues), const Size(390, 844));
    await tester.tap(find.byTooltip('Configurações da fila'));
    await tick(tester);
    await tick(tester);
    expect(find.byType(QueueSettingsScreen), findsNothing);
    expect(find.text('Esta fila não existe mais'), findsOneWidget);
  });

  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 1.5]) {
      for (final owner in [true, false]) {
        testWidgets('no overflow at $width x$scale owner=$owner', (
          tester,
        ) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pumpApp(
            tester,
            panel(service(), isOwner: owner),
            size: Size(width, 900),
          );
          await tick(tester);
          expect(tester.takeException(), isNull);
          expect(find.byType(CurrentCalledCard), findsOneWidget);
          if (owner) {
            expect(find.byTooltip('Configurações da fila'), findsOneWidget);
          }
          expect(find.byTooltip('QR code da fila'), findsOneWidget);
        });
      }
    }
  }

  testWidgets('compact bar keeps history and status in the more menu', (
    tester,
  ) async {
    await pumpApp(tester, panel(service()), size: const Size(320, 900));
    await tick(tester);
    expect(find.text('Pausar'), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byTooltip('Mais ações'),
      ),
    );
    await tick(tester);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
    expect(find.text('Fechar'), findsOneWidget);
  });

  testWidgets('closed queue on phone hides settings, wide shows them', (
    tester,
  ) async {
    await pumpApp(
      tester,
      panel(service(status: QueueStatus.closed)),
      size: const Size(390, 900),
    );
    await tick(tester);
    expect(find.text('Fila fechada'), findsOneWidget);
    expect(find.byType(QueueQrCard), findsNothing);
    expect(find.byType(OperatorsTile), findsNothing);
    expect(find.byTooltip('Configurações da fila'), findsOneWidget);

    await pumpApp(
      tester,
      panel(service(status: QueueStatus.closed)),
      size: const Size(1200, 4000),
    );
    await tick(tester);
    expect(find.text('Fila fechada'), findsOneWidget);
    expect(find.byType(QueueQrCard), findsOneWidget);
    expect(find.byType(AlertsTile), findsOneWidget);
  });

  testWidgets('paused queue on phone still shows the list first', (
    tester,
  ) async {
    await pumpApp(
      tester,
      panel(service(status: QueueStatus.paused)),
      size: const Size(390, 900),
    );
    await tick(tester);
    expect(find.byType(CurrentCalledCard), findsOneWidget);
    expect(find.byType(WaitingTile), findsOneWidget);
    expect(find.byType(QueueQrCard), findsNothing);

    await pumpApp(
      tester,
      panel(service(status: QueueStatus.paused)),
      size: const Size(1200, 1000),
    );
    await tick(tester);
    expect(find.byType(QueueQrCard), findsOneWidget);
    expect(find.byType(CurrentCalledCard), findsOneWidget);
  });

  testWidgets('tour points at the settings target when QR is unavailable', (
    tester,
  ) async {
    final qrKey = GlobalKey();
    final settingsKey = GlobalKey();
    final callKey = GlobalKey();
    late AppLocalizations l10n;
    Widget host(List<Widget> children) => Builder(
      builder: (context) {
        l10n = AppLocalizations.of(context);
        return Column(children: children);
      },
    );
    await pumpApp(tester, host([SizedBox(key: settingsKey)]));
    var steps = panelTourSteps(l10n, qrKey, settingsKey, callKey);
    expect(steps.first.key, settingsKey);
    expect(steps.first.title, l10n.tourPanelSettingsTitle);
    await pumpApp(
      tester,
      host([SizedBox(key: qrKey), SizedBox(key: settingsKey)]),
    );
    steps = panelTourSteps(l10n, qrKey, settingsKey, callKey);
    expect(steps.first.key, qrKey);
    expect(steps.first.title, l10n.tourPanelQrTitle);
  });
}
