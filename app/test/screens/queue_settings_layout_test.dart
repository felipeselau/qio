import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_entry.dart';
import 'package:qio_app/screens/queue_panel_screen.dart';
import 'package:qio_app/screens/queue_settings_screen.dart';
import 'package:qio_app/widgets/queue_panel/alerts_tile.dart';
import 'package:qio_app/widgets/queue_panel/current_called_card.dart';
import 'package:qio_app/widgets/queue_panel/edit_queue_tile.dart';
import 'package:qio_app/widgets/queue_panel/operators_tile.dart';
import 'package:qio_app/widgets/queue_panel/queue_action_bar.dart';
import 'package:qio_app/widgets/queue_panel/queue_qr_card.dart';
import 'package:qio_app/widgets/queue_panel/waiting_tile.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';
import '../helpers/panel_menu.dart';

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Widget panel({bool isOwner = true}) => QueuePanelScreen(
  queueId: 'q1',
  queueName: 'Padaria',
  isOwner: isOwner,
  queues: FakeQueueService(
    queues: {'q1': fakeQueue('q1', name: 'Padaria')},
    entries: {
      'q1': [
        fakeEntry('e1', 1, name: 'Ana', status: EntryStatus.called),
        fakeEntry('e2', 2, name: 'Bruno'),
      ],
    },
  ),
  operators: FakeOperatorService(),
  groups: FakeGroupService(),
  showTour: false,
);

void main() {
  testWidgets('phone shows the current card and list before any setting', (
    tester,
  ) async {
    await pumpApp(tester, panel(), size: const Size(390, 844));
    await tick(tester);
    expect(find.byType(CurrentCalledCard), findsOneWidget);
    expect(find.byType(WaitingTile), findsOneWidget);
    expect(find.byType(QueueActionBar), findsOneWidget);
    expect(find.byType(QueueQrCard), findsNothing);
    expect(find.byType(OperatorsTile), findsNothing);
    expect(find.byType(AlertsTile), findsNothing);
    final cardTop = tester.getTopLeft(find.byType(CurrentCalledCard)).dy;
    expect(cardTop, lessThan(200));
  });

  testWidgets('gear opens settings with the owner tiles', (tester) async {
    await pumpApp(tester, panel(), size: const Size(390, 2400));
    await tick(tester);
    await tapPanelAction(tester, 'Configurações da fila');
    await tick(tester);
    expect(find.byType(QueueSettingsScreen), findsOneWidget);
    expect(find.byType(QueueQrCard), findsOneWidget);
    expect(find.byType(OperatorsTile), findsOneWidget);
    expect(find.byType(AlertsTile), findsOneWidget);
    expect(find.byType(EditQueueTile), findsOneWidget);
  });

  testWidgets('QR shortcut opens the settings screen', (tester) async {
    await pumpApp(tester, panel(), size: const Size(390, 2400));
    await tick(tester);
    await tapPanelAction(tester, 'QR code da fila');
    await tick(tester);
    expect(find.byType(QueueSettingsScreen), findsOneWidget);
    expect(find.byType(QueueQrCard), findsOneWidget);
  });

  testWidgets('operator has no gear and sees no owner tiles', (tester) async {
    await pumpApp(tester, panel(isOwner: false), size: const Size(390, 2400));
    await tick(tester);
    expect(find.byTooltip('Configurações da fila'), findsNothing);
    await tapPanelAction(tester, 'QR code da fila');
    await tick(tester);
    expect(find.byType(QueueQrCard), findsOneWidget);
    expect(find.byType(OperatorsTile), findsNothing);
    expect(find.byType(AlertsTile), findsNothing);
    expect(find.byType(EditQueueTile), findsNothing);
  });

  testWidgets('shortcuts meet the 48dp tap target', (tester) async {
    await pumpApp(tester, panel(), size: const Size(700, 844));
    await tick(tester);
    for (final tip in ['Configurações da fila', 'QR code da fila']) {
      final size = tester.getSize(
        find.ancestor(
          of: find.byTooltip(tip),
          matching: find.byType(IconButton),
        ),
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('wide layout keeps two columns with no shortcuts', (
    tester,
  ) async {
    await pumpApp(tester, panel(), size: const Size(1200, 1000));
    await tick(tester);
    expect(find.byType(QueueQrCard), findsOneWidget);
    expect(find.byType(OperatorsTile), findsOneWidget);
    expect(find.byType(CurrentCalledCard), findsOneWidget);
    expect(find.byTooltip('Configurações da fila'), findsNothing);
    final qrX = tester.getTopLeft(find.byType(QueueQrCard)).dx;
    final cardX = tester.getTopLeft(find.byType(CurrentCalledCard)).dx;
    expect(cardX, greaterThan(qrX + 300));
  });
}
