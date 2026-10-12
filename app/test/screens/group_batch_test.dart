import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_group.dart';
import 'package:qio_app/screens/groups_screen.dart';
import 'package:qio_app/screens/queue_panel_screen.dart';
import 'package:qio_app/services/queue_service.dart';
import 'package:qio_app/widgets/group_chip.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';
import 'home_grouped_test.dart' show homeWith, pumpTall, qg, tick;

final _groups = [qg('g1', 'Loja Centro'), qg('g2', 'Anexo')];

const _menuTip = 'Ações em lote do grupo Loja Centro';

List<Queue> _sample({QueueStatus status = QueueStatus.open}) => [
  fakeQueue('a', name: 'Caixa 1', groupId: 'g1', status: status),
  fakeQueue('b', name: 'Caixa 2', groupId: 'g1', status: status),
  fakeQueue('c', name: 'Caixa 3', groupId: 'g1', status: status),
  fakeQueue('d', name: 'Balcao', groupId: 'g2', status: status),
  fakeQueue('e', name: 'Solta'),
];

Future<FakeQueueService> pumpHome(
  WidgetTester tester, {
  List<Queue>? queues,
}) async {
  final home = homeWith(queues: queues ?? _sample(), groups: _groups);
  await pumpTall(tester, home);
  await tick(tester);
  return home.queues! as FakeQueueService;
}

Finder dlgBtn(String label) => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.widgetWithText(TextButton, label),
);

Future<void> openMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_menuTip));
  await tester.pumpAndSettle();
}

void main() {
  group('groups screen counts', () {
    Future<FakeGroupService> pumpGroups(WidgetTester tester) async {
      final groups = FakeGroupService(groups: _groups);
      final queues = FakeQueueService(
        ownerQueues: [
          fakeQueue('a', groupId: 'g1'),
          fakeQueue('b', groupId: 'g1'),
          fakeQueue('c', groupId: 'g2'),
          fakeQueue('d', groupId: 'gone'),
          fakeQueue('e'),
        ],
      );
      await pumpApp(tester, GroupsScreen(groups: groups, queues: queues));
      await tick(tester);
      return groups;
    }

    testWidgets('shows queue count per group', (tester) async {
      await pumpGroups(tester);
      expect(find.text('2 filas'), findsOneWidget);
      expect(find.text('1 fila'), findsOneWidget);
    });

    testWidgets('empty group says Sem filas', (tester) async {
      final groups = FakeGroupService(groups: _groups);
      final queues = FakeQueueService(
        ownerQueues: [fakeQueue('a', groupId: 'g1')],
      );
      await pumpApp(tester, GroupsScreen(groups: groups, queues: queues));
      await tick(tester);
      expect(find.text('Sem filas'), findsOneWidget);
      expect(find.text('1 fila'), findsOneWidget);
    });

    testWidgets('delete dialog uses the real count', (tester) async {
      final groups = await pumpGroups(tester);
      await tester.tap(find.byTooltip('Excluir grupo').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('2 filas ficarão sem grupo.'), findsOneWidget);
      await tester.tap(find.text('Excluir').first);
      await tester.pumpAndSettle();
      expect(groups.calls, contains('deleteGroup:g1'));
    });

    testWidgets('singular in the delete dialog', (tester) async {
      await pumpGroups(tester);
      await tester.tap(find.byTooltip('Excluir grupo').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('1 fila ficará sem grupo.'), findsOneWidget);
    });

    testWidgets('zero queues keeps the original text', (tester) async {
      final groups = FakeGroupService(groups: _groups);
      final queues = FakeQueueService(ownerQueues: const []);
      await pumpApp(tester, GroupsScreen(groups: groups, queues: queues));
      await tick(tester);
      await tester.tap(find.byTooltip('Excluir grupo').first);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('As filas dele ficam sem grupo.'),
        findsOneWidget,
      );
    });
  });

  group('group chip', () {
    testWidgets('GroupChip exposes the group in its semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const Scaffold(body: GroupChip(name: 'Anexo')));
      expect(find.text('Anexo'), findsOneWidget);
      expect(find.bySemanticsLabel('Grupo: Anexo'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('home cards inside sections do not repeat the group', (
      tester,
    ) async {
      await pumpHome(tester);
      expect(find.byType(GroupChip), findsNothing);
    });

    testWidgets('home flat list never shows a chip without groups', (
      tester,
    ) async {
      await pumpTall(tester, homeWith(queues: [fakeQueue('a', name: 'Solta')]));
      await tick(tester);
      expect(find.byType(GroupChip), findsNothing);
    });

    FakeQueueService panelQueues({String? groupId}) => FakeQueueService(
      queues: {'q1': fakeQueue('q1', name: 'Padaria', groupId: groupId)},
      entries: {'q1': const []},
    );

    Future<void> pumpPanel(
      WidgetTester tester,
      FakeQueueService queues, {
      bool isOwner = true,
      List<QueueGroup>? groups,
    }) async {
      await pumpApp(
        tester,
        QueuePanelScreen(
          queueId: 'q1',
          queueName: 'Padaria',
          isOwner: isOwner,
          queues: queues,
          operators: FakeOperatorService(),
          groups: FakeGroupService(groups: groups ?? _groups),
          showTour: false,
        ),
        size: const Size(390, 2600),
      );
      await tick(tester);
    }

    testWidgets('panel shows the group chip for the owner', (tester) async {
      await pumpPanel(tester, panelQueues(groupId: 'g1'));
      expect(find.widgetWithText(GroupChip, 'Loja Centro'), findsOneWidget);
    });

    testWidgets('panel without group shows no chip', (tester) async {
      await pumpPanel(tester, panelQueues());
      expect(find.byType(GroupChip), findsNothing);
    });

    testWidgets('orphan group id shows no chip', (tester) async {
      await pumpPanel(tester, panelQueues(groupId: 'gone'));
      expect(find.byType(GroupChip), findsNothing);
    });

    testWidgets('operator never sees the group', (tester) async {
      await pumpPanel(tester, panelQueues(groupId: 'g1'), isOwner: false);
      expect(find.byType(GroupChip), findsNothing);
    });
  });

  group('home batch menu', () {
    testWidgets('header has an accessible menu with a 48 dp target', (
      tester,
    ) async {
      await pumpHome(tester);
      expect(find.byTooltip(_menuTip), findsOneWidget);
      expect(find.byTooltip('Ações em lote do grupo Anexo'), findsOneWidget);
      final size = tester.getSize(find.byTooltip(_menuTip));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('ungrouped section has no menu', (tester) async {
      await pumpHome(tester);
      expect(find.byIcon(Icons.more_vert), findsNWidgets(2));
    });

    testWidgets('all open offers pause and close, not reopen', (tester) async {
      await pumpHome(tester);
      await openMenu(tester);
      expect(find.text('Pausar todas'), findsOneWidget);
      expect(find.text('Fechar todas'), findsOneWidget);
      expect(find.text('Reabrir todas'), findsNothing);
    });

    testWidgets('reopen appears only when something is not open', (
      tester,
    ) async {
      await pumpHome(
        tester,
        queues: [
          fakeQueue('a', groupId: 'g1', status: QueueStatus.paused),
          fakeQueue('b', groupId: 'g1'),
        ],
      );
      await openMenu(tester);
      expect(find.text('Reabrir todas'), findsOneWidget);
    });

    testWidgets('all paused hides Pausar todas', (tester) async {
      await pumpHome(tester, queues: _sample(status: QueueStatus.paused));
      await openMenu(tester);
      expect(find.text('Pausar todas'), findsNothing);
      expect(find.text('Fechar todas'), findsOneWidget);
      expect(find.text('Reabrir todas'), findsOneWidget);
    });

    testWidgets('pause flow: message dialog, confirmation, snackbar', (
      tester,
    ) async {
      final queues = await pumpHome(tester);
      await openMenu(tester);
      await tester.tap(find.text('Pausar todas'));
      await tester.pumpAndSettle();
      expect(find.text('Pausar a fila'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Volto logo');
      await tester.tap(dlgBtn('Pausar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Pausar 3 filas do grupo "Loja Centro"?'),
        findsOneWidget,
      );
      expect(queues.calls.where((c) => c.startsWith('groupStatus')), isEmpty);
      await tester.tap(dlgBtn('Pausar'));
      await tester.pumpAndSettle();
      expect(queues.calls, contains('groupStatus:g1:paused'));
      expect(queues.lastStatusMessage, 'Volto logo');
      expect(find.text('2 filas atualizadas'), findsOneWidget);
    });

    testWidgets('close flow asks for the message and confirms', (tester) async {
      final queues = await pumpHome(tester);
      await openMenu(tester);
      await tester.tap(find.text('Fechar todas'));
      await tester.pumpAndSettle();
      expect(find.text('Fechar a fila'), findsOneWidget);
      await tester.tap(dlgBtn('Fechar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Fechar 3 filas do grupo "Loja Centro"?'),
        findsOneWidget,
      );
      await tester.tap(dlgBtn('Fechar'));
      await tester.pumpAndSettle();
      expect(queues.calls, contains('groupStatus:g1:closed'));
    });

    testWidgets('reopen skips the message dialog', (tester) async {
      final queues = await pumpHome(
        tester,
        queues: _sample(status: QueueStatus.paused),
      );
      await openMenu(tester);
      await tester.tap(find.text('Reabrir todas'));
      await tester.pumpAndSettle();
      expect(find.text('Pausar a fila'), findsNothing);
      expect(
        find.text('Reabrir 3 filas do grupo "Loja Centro"?'),
        findsOneWidget,
      );
      await tester.tap(dlgBtn('Reabrir'));
      await tester.pumpAndSettle();
      expect(queues.calls, contains('groupStatus:g1:open'));
      expect(queues.lastStatusMessage, isNull);
    });

    testWidgets('cancelling the confirmation writes nothing', (tester) async {
      final queues = await pumpHome(tester);
      await openMenu(tester);
      await tester.tap(find.text('Fechar todas'));
      await tester.pumpAndSettle();
      await tester.tap(dlgBtn('Fechar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(queues.calls.where((c) => c.startsWith('groupStatus')), isEmpty);
    });

    testWidgets('partial failure reports done of total', (tester) async {
      final queues = await pumpHome(tester);
      queues.groupStatusResult = const GroupStatusResult(total: 5, updated: 3);
      await openMenu(tester);
      await tester.tap(find.text('Fechar todas'));
      await tester.pumpAndSettle();
      await tester.tap(dlgBtn('Fechar'));
      await tester.pumpAndSettle();
      await tester.tap(dlgBtn('Fechar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 de 5 atualizadas'), findsOneWidget);
    });

    testWidgets('a thrown error shows the error snackbar', (tester) async {
      final queues = await pumpHome(tester);
      queues.groupStatusError = Exception('boom');
      await openMenu(tester);
      await tester.tap(find.text('Fechar todas'));
      await tester.pumpAndSettle();
      await tester.tap(dlgBtn('Fechar'));
      await tester.pumpAndSettle();
      await tester.tap(dlgBtn('Fechar'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('2 filas atualizadas'), findsNothing);
    });

    testWidgets('menu is disabled while a batch is running', (tester) async {
      final queues = await pumpHome(tester);
      final gate = Completer<void>();
      queues.groupStatusGate = gate.future;
      await openMenu(tester);
      await tester.tap(find.text('Fechar todas'));
      await tester.pumpAndSettle();
      await tester.tap(dlgBtn('Fechar'));
      await tester.pumpAndSettle();
      await tester.tap(dlgBtn('Fechar'));
      await tester.pump();
      await tester.tap(find.byTooltip(_menuTip), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Fechar todas'), findsNothing);
      gate.complete();
      await tester.pumpAndSettle();
      expect(queues.calls.where((c) => c.startsWith('groupStatus')).length, 1);
    });

    testWidgets('english labels', (tester) async {
      final home = homeWith(queues: _sample(), groups: _groups);
      await pumpTall(tester, home, locale: const Locale('en'));
      await tick(tester);
      await tester.tap(find.byTooltip('Batch actions for group Loja Centro'));
      await tester.pumpAndSettle();
      expect(find.text('Pause all'), findsOneWidget);
      expect(find.text('Close all'), findsOneWidget);
    });
  });
}
