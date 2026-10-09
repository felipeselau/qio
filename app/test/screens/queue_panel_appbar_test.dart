import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_entry.dart';
import 'package:qio_app/screens/queue_panel_screen.dart';
import 'package:qio_app/widgets/queue_panel/queue_panel_title.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

FakeQueueService service({String name = 'Padaria'}) => FakeQueueService(
  queues: {'q1': fakeQueue('q1', name: name, status: QueueStatus.open)},
  entries: {
    'q1': [
      fakeEntry('e1', 1, name: 'Ana', status: EntryStatus.called),
      fakeEntry('e2', 2, name: 'Bruno'),
    ],
  },
);

QueuePanelScreen panel(FakeQueueService queues, {bool isOwner = true}) =>
    QueuePanelScreen(
      queueId: 'q1',
      queueName: 'Padaria',
      isOwner: isOwner,
      queues: queues,
      operators: FakeOperatorService(),
      manualEntries: FakeManualEntryService(),
      groups: FakeGroupService(),
      showTour: false,
    );

Finder get appBarMenu => find.descendant(
  of: find.byType(AppBar),
  matching: find.byTooltip('Mais ações'),
);

void main() {
  for (final width in [320.0, 360.0, 390.0, 430.0, 466.0, 600.0]) {
    for (final scale in [1.0, 1.5]) {
      for (final owner in [true, false]) {
        testWidgets('appbar sem overflow a $width x$scale owner=$owner', (
          tester,
        ) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pumpApp(
            tester,
            panel(service(name: 'Atendimento FuelTech'), isOwner: owner),
            size: Size(width, 900),
          );
          await tick(tester);
          expect(tester.takeException(), isNull);
          expect(find.byTooltip('Adicionar pessoa'), findsOneWidget);
          final compact = width < 600 || scale > 1.2;
          expect(appBarMenu, compact ? findsOneWidget : findsNothing);
        });
      }
    }
  }

  testWidgets('título usa fonte normal e não fica dentro de FittedBox', (
    tester,
  ) async {
    await pumpApp(
      tester,
      panel(service(name: 'Atendimento FuelTech')),
      size: const Size(466, 900),
    );
    await tick(tester);
    final title = find.descendant(
      of: find.byType(QueuePanelTitle),
      matching: find.text('Atendimento FuelTech'),
    );
    expect(title, findsOneWidget);
    final text = tester.widget<Text>(title);
    expect(text.style!.fontSize, greaterThanOrEqualTo(14));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(
      find.descendant(
        of: find.byType(QueuePanelTitle),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );
    expect(find.text('Aberta'), findsOneWidget);
  });

  testWidgets('nome longo é cortado com reticências, sem reduzir a fonte', (
    tester,
  ) async {
    const name = 'Atendimento ao cliente da unidade central de manutenção';
    await pumpApp(
      tester,
      panel(service(name: name)),
      size: const Size(360, 900),
    );
    await tick(tester);
    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(QueuePanelTitle),
        matching: find.text(name),
      ),
    );
    expect(text.style!.fontSize, greaterThanOrEqualTo(14));
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets(
    'menu compacto do dono tem QR, configurações, histórico e status',
    (tester) async {
      await pumpApp(tester, panel(service()), size: const Size(466, 900));
      await tick(tester);
      await tester.tap(appBarMenu);
      await tester.pumpAndSettle();
      for (final label in [
        'QR code da fila',
        'Configurações da fila',
        'Histórico',
        'Pausar',
        'Fechar',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    },
  );

  testWidgets('menu compacto do operador só tem o QR', (tester) async {
    await pumpApp(
      tester,
      panel(service(), isOwner: false),
      size: const Size(466, 900),
    );
    await tick(tester);
    await tester.tap(appBarMenu);
    await tester.pumpAndSettle();
    expect(find.text('QR code da fila'), findsOneWidget);
    expect(find.text('Configurações da fila'), findsNothing);
    expect(find.text('Histórico'), findsNothing);
    expect(find.text('Pausar'), findsNothing);
  });

  testWidgets('a partir de 600 dp as ações ficam visíveis como antes', (
    tester,
  ) async {
    await pumpApp(tester, panel(service()), size: const Size(700, 900));
    await tick(tester);
    expect(find.byTooltip('QR code da fila'), findsOneWidget);
    expect(find.byTooltip('Configurações da fila'), findsOneWidget);
    expect(find.byTooltip('Histórico'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
  });

  testWidgets('alvos de toque da AppBar têm pelo menos 48 dp', (tester) async {
    await pumpApp(tester, panel(service()), size: const Size(390, 900));
    await tick(tester);
    for (final finder in [appBarMenu, find.byTooltip('Adicionar pessoa')]) {
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('badge vira ponto com Semantics quando falta espaço', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 60,
          child: QueuePanelTitle(
            queueId: 'q1',
            queueName: 'Padaria',
            queues: service(),
          ),
        ),
      ),
    );
    await tick(tester);
    expect(find.text('Aberta'), findsNothing);
    expect(find.bySemanticsLabel('Aberta'), findsOneWidget);
  });
}
