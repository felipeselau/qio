import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_group.dart';
import 'package:qio_app/models/queue_slot.dart';
import 'package:qio_app/screens/create_queue_screen.dart';
import 'package:qio_app/screens/queue_panel_screen.dart';
import 'package:qio_app/widgets/queue_form/schedule_form.dart';

import '../helpers/create_queue_flow.dart';
import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

Future<void> openFromLauncher(
  WidgetTester tester, {
  FakeQueueService? queues,
  FakeGroupService? groups,
}) async {
  await pumpApp(
    tester,
    Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CreateQueueScreen(
              queues: queues ?? FakeQueueService(),
              groups: groups ?? FakeGroupService(),
            ),
          ),
        ),
        child: const Text('abrir'),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  group('só o nome', () {
    testWidgets('Criar agora cria a fila com defaults', (tester) async {
      final queues = await pumpCreate(tester);
      await typeName(tester, '  Padaria ');
      await tapKey(tester, 'create-quick');

      expect(queues.calls, ['create:Padaria:queue:0']);
      final args = queues.createdArgs!;
      expect(args.description, isNull);
      expect(args.avgServiceMin, 10);
      expect(args.maxWaiting, 0);
      expect(args.groupId, isNull);
      expect(args.expiry, isNull);
      expect(queues.createdSchedule, isNull);
      expect(queues.createdBrandColor, isNull);
    });

    testWidgets('caminho completo até a revisão cria com defaults', (
      tester,
    ) async {
      final queues = await pumpCreate(tester);
      await goToReview(tester, name: 'Padaria');

      expect(find.text('Padaria'), findsOneWidget);
      expect(find.text('Fila por chegada'), findsOneWidget);
      expect(find.text('Tempo médio: 10 min'), findsOneWidget);
      expect(find.text('Limite de espera: Sem limite'), findsOneWidget);
      expect(find.text('Padrão'), findsOneWidget);
      expect(find.text('Sempre aberta'), findsOneWidget);
      expect(find.text('Não expirar'), findsOneWidget);
      expect(queues.calls, isEmpty);

      await tapKey(tester, 'create-submit');
      expect(queues.calls, ['create:Padaria:queue:0']);
      expect(queues.createdArgs!.avgServiceMin, 10);
      expect(queues.createdArgs!.maxWaiting, 0);
    });

    testWidgets('nome é obrigatório e bloqueia o passo', (tester) async {
      final queues = await pumpCreate(tester);
      expect(find.text('Descrição (opcional)'), findsNothing);

      await tapKey(tester, 'create-continue');
      expect(find.text('Informe o nome'), findsOneWidget);
      expect(byKeyName('create-name'), findsOneWidget);

      await tapKey(tester, 'create-quick');
      expect(queues.calls, isEmpty);
      expect(byKeyName('create-name'), findsOneWidget);
    });

    testWidgets('Enter no nome avança para o próximo passo', (tester) async {
      await pumpCreate(tester);
      await typeName(tester, 'Clínica');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(byKeyName('create-mode-queue'), findsOneWidget);
    });
  });

  group('valores do wizard', () {
    testWidgets('todos os passos chegam ao serviço', (tester) async {
      final handle = tester.ensureSemantics();
      final queues = await pumpCreate(tester);
      await typeName(tester, 'Clínica');
      await tapFinder(tester, find.text('Mais detalhes'));
      await enterKey(tester, 'create-description', 'Sala 2');
      await tapKey(tester, 'create-continue');

      await tapKey(tester, 'create-continue');

      await enterKey(tester, 'create-avg', '20');
      await enterKey(tester, 'create-limit', '30');
      await tapKey(tester, 'create-continue');

      await tester.tap(find.bySemanticsLabel('#7C3AED'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'create-continue');

      await tapFinder(
        tester,
        find.descendant(
          of: byKeyName('create-schedule'),
          matching: find.byType(Switch),
        ),
      );
      await tapKey(tester, 'expiry-enabled');
      expect(byKeyName('expiry-clear'), findsNothing);
      expect(byKeyName('expiry-reset'), findsNothing);
      await tapKey(tester, 'create-continue');

      expect(find.text('Tempo médio: 20 min'), findsOneWidget);
      expect(find.text('Limite de espera: 30 pessoas'), findsOneWidget);
      expect(find.text('#7C3AED'), findsOneWidget);
      expect(find.text('Expirar após 12 h'), findsOneWidget);
      expect(find.text('Sempre aberta'), findsNothing);

      await tapKey(tester, 'create-submit');
      final args = queues.createdArgs!;
      expect(args.description, 'Sala 2');
      expect(args.avgServiceMin, 20);
      expect(args.maxWaiting, 30);
      expect(queues.createdBrandColor, '#7C3AED');
      expect(queues.createdSchedule!.enabled, isTrue);
      expect(queues.createdSchedule!.windows.single.days, [1, 2, 3, 4, 5]);
      expect(args.expiry!.enabled, isTrue);
      expect(args.expiry!.hours, 12);
      handle.dispose();
    });

    testWidgets('tempo médio inválido bloqueia o passo', (tester) async {
      final queues = await pumpCreate(tester);
      await typeName(tester, 'Clínica');
      await continueSteps(tester, 2);
      await enterKey(tester, 'create-avg', '241');
      await tapKey(tester, 'create-continue');
      expect(find.text('Informe de 1 a 240 minutos'), findsOneWidget);
      expect(byKeyName('create-avg'), findsOneWidget);
      expect(queues.calls, isEmpty);
    });

    testWidgets('limite inválido bloqueia o passo', (tester) async {
      await pumpCreate(tester);
      await typeName(tester, 'Clínica');
      await continueSteps(tester, 2);
      await enterKey(tester, 'create-limit', '5000');
      await tapKey(tester, 'create-continue');
      expect(find.text('Use um número de 1 a 1000'), findsOneWidget);
      expect(byKeyName('create-limit'), findsOneWidget);
    });

    testWidgets('descrição inválida abre Mais detalhes', (tester) async {
      await pumpCreate(tester);
      await typeName(tester, 'Clínica');
      await tapFinder(tester, find.text('Mais detalhes'));
      await enterKey(tester, 'create-description', 'a' * 301);
      await tapFinder(tester, find.text('Mais detalhes'));
      expect(find.text('Descrição (opcional)'), findsNothing);

      await tapKey(tester, 'create-continue');
      expect(find.text('Descrição (opcional)'), findsOneWidget);
      expect(byKeyName('create-name'), findsOneWidget);
    });

    testWidgets('horário de funcionamento sem dias bloqueia o passo', (
      tester,
    ) async {
      await pumpCreate(tester);
      await typeName(tester, 'Clínica');
      await continueSteps(tester, 4);
      await tapFinder(
        tester,
        find.descendant(
          of: byKeyName('create-schedule'),
          matching: find.byType(Switch),
        ),
      );
      for (var day = 1; day <= 5; day++) {
        await tapFinder(
          tester,
          find.widgetWithText(FilterChip, dayLabel(day, 'pt')),
        );
      }
      await tapKey(tester, 'create-continue');
      expect(find.text('Escolha ao menos um dia'), findsOneWidget);
      expect(byKeyName('create-schedule'), findsOneWidget);
    });
  });

  group('navegação', () {
    testWidgets('voltar preserva os valores', (tester) async {
      await pumpCreate(tester);
      await typeName(tester, 'Clínica');
      await continueSteps(tester, 2);
      await enterKey(tester, 'create-avg', '15');
      await tapKey(tester, 'create-back');
      expect(byKeyName('create-mode-queue'), findsOneWidget);
      await tapKey(tester, 'create-back');
      expect(textOf(tester, 'create-name'), 'Clínica');
      await continueSteps(tester, 2);
      expect(textOf(tester, 'create-avg'), '15');
    });

    testWidgets('modo e horários sobrevivem a voltar', (tester) async {
      await pumpCreate(tester);
      await typeName(tester, 'Clínica');
      await tapKey(tester, 'create-continue');
      await tapKey(tester, 'create-mode-schedule');
      await tapKey(tester, 'create-suggest-60');
      await tapKey(tester, 'create-back');
      await tapKey(tester, 'create-continue');
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('16:00'), findsOneWidget);
    });

    testWidgets('pular mantém os defaults', (tester) async {
      await pumpCreate(tester);
      await typeName(tester, 'Clínica');
      await continueSteps(tester, 2);
      await enterKey(tester, 'create-avg', '25');
      await tapKey(tester, 'create-skip');
      expect(byKeyName('create-color'), findsOneWidget);
      await tapKey(tester, 'create-skip');
      await tapKey(tester, 'create-skip');

      expect(byKeyName('create-submit'), findsOneWidget);
      expect(find.text('Tempo médio: 10 min'), findsOneWidget);
      expect(find.text('Sempre aberta'), findsOneWidget);
    });

    testWidgets('Editar na revisão volta ao passo e retorna à revisão', (
      tester,
    ) async {
      final queues = await pumpCreate(tester);
      await goToReview(tester);

      await tapKey(tester, 'create-edit-capacity');
      expect(byKeyName('create-avg'), findsOneWidget);
      await enterKey(tester, 'create-avg', '25');
      await tapKey(tester, 'create-continue');

      expect(byKeyName('create-submit'), findsOneWidget);
      expect(find.text('Tempo médio: 25 min'), findsOneWidget);

      await tapKey(tester, 'create-edit-name');
      await typeName(tester, 'Clínica Nova');
      await tapKey(tester, 'create-continue');
      expect(find.text('Clínica Nova'), findsOneWidget);

      await tapKey(tester, 'create-submit');
      expect(queues.calls, ['create:Clínica Nova:queue:0']);
      expect(queues.createdArgs!.avgServiceMin, 25);
    });

    testWidgets('voltar do sistema volta um passo e depois confirma', (
      tester,
    ) async {
      await openFromLauncher(tester);
      await typeName(tester, 'Algo');
      await tapKey(tester, 'create-continue');
      expect(byKeyName('create-mode-queue'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(byKeyName('create-name'), findsOneWidget);
      expect(find.text('Continuar editando'), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Continuar editando'), findsOneWidget);
    });

    testWidgets('descartar sai da tela e continuar editando fica', (
      tester,
    ) async {
      await openFromLauncher(tester);
      await typeName(tester, 'Algo');
      await tapKey(tester, 'create-back');
      expect(find.text('Descartar alterações?'), findsOneWidget);

      await tester.tap(find.text('Continuar editando'));
      await tester.pumpAndSettle();
      expect(byKeyName('create-name'), findsOneWidget);

      await tapKey(tester, 'create-back');
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      expect(byKeyName('create-name'), findsNothing);
      expect(find.text('abrir'), findsOneWidget);
    });

    testWidgets('tela intocada sai sem confirmação', (tester) async {
      await openFromLauncher(tester);
      await tapKey(tester, 'create-back');
      expect(find.text('Descartar alterações?'), findsNothing);
      expect(find.text('abrir'), findsOneWidget);
    });
  });

  group('criação em andamento', () {
    testWidgets('voltar fica bloqueado enquanto cria na revisão', (
      tester,
    ) async {
      final gate = Completer<void>();
      final queues = FakeQueueService()..createGate = gate.future;
      await openFromLauncher(tester, queues: queues);
      await goToReview(tester);
      await tester.tap(byKeyName('create-submit'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.tap(byKeyName('create-back'));
      await tester.pump();
      expect(byKeyName('create-submit'), findsOneWidget);
      expect(find.text('abrir'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(byKeyName('create-error'), findsOneWidget);
    });

    testWidgets('Criar agora seguido de voltar não sai da tela', (
      tester,
    ) async {
      final gate = Completer<void>();
      final queues = FakeQueueService()..createGate = gate.future;
      await openFromLauncher(tester, queues: queues);
      await typeName(tester, 'Padaria');
      await tester.tap(byKeyName('create-quick'));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.tap(byKeyName('create-back'));
      await tester.pump();
      expect(byKeyName('create-name'), findsOneWidget);
      expect(find.text('Descartar alterações?'), findsNothing);
      expect(find.text('abrir'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('timeout de 20 s libera a tela com aviso', (tester) async {
      final queues = FakeQueueService()..createGate = Completer<void>().future;
      await pumpCreate(tester, queues: queues);
      await goToReview(tester);
      await tester.tap(byKeyName('create-submit'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 21));

      expect(
        find.text(
          'Sem resposta. A fila pode ter sido criada: confira sua lista '
          'antes de tentar de novo.',
        ),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('passo 1 e revisão', () {
    testWidgets('voltar ao passo 1 mantém Mais detalhes e não foca o nome', (
      tester,
    ) async {
      await pumpCreate(tester);
      await typeName(tester, 'Clínica');
      await tapFinder(tester, find.text('Mais detalhes'));
      await enterKey(tester, 'create-description', 'Sala 2');
      await tapKey(tester, 'create-continue');
      await tapKey(tester, 'create-back');

      expect(textOf(tester, 'create-description'), 'Sala 2');
      expect(find.text('Descrição (opcional)'), findsOneWidget);
      final name = tester.widget<EditableText>(
        find.descendant(
          of: byKeyName('create-name'),
          matching: find.byType(EditableText),
        ),
      );
      expect(name.focusNode.hasFocus, isFalse);
    });

    testWidgets('revisão mostra o nome do grupo e a cor', (tester) async {
      final groups = FakeGroupService(
        groups: [
          QueueGroup(id: 'g1', name: 'Loja Centro', createdAt: DateTime(2025)),
        ],
      );
      await openFromLauncher(tester, groups: groups);
      await typeName(tester, 'Clínica');
      await tapFinder(tester, find.text('Mais detalhes'));
      await tapFinder(
        tester,
        find.descendant(
          of: byKeyName('create-group'),
          matching: find.byType(DropdownButtonFormField<String?>),
        ),
      );
      await tester.tap(find.text('Loja Centro').last);
      await tester.pumpAndSettle();
      await continueSteps(tester, 3);
      await tester.tap(find.bySemanticsLabel('#7C3AED'));
      await tester.pumpAndSettle();
      await continueSteps(tester, 2);

      expect(find.text('Loja Centro'), findsOneWidget);
      expect(byKeyName('create-review-group'), findsOneWidget);
      expect(byKeyName('create-review-color'), findsOneWidget);
    });

    testWidgets('rodapé mantém a altura entre passos', (tester) async {
      await pumpCreate(tester);
      await typeName(tester, 'Clínica');
      final first = tester.getSize(byKeyName('create-continue')).height;
      final top1 = tester.getTopLeft(byKeyName('create-continue')).dy;
      await continueSteps(tester, 5);
      expect(byKeyName('create-submit'), findsOneWidget);
      expect(tester.getSize(byKeyName('create-submit')).height, first);
      expect(tester.getTopLeft(byKeyName('create-submit')).dy, top1);
    });

    testWidgets('revisão com texto 2.0x em 320 px sem overflow', (
      tester,
    ) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: CreateQueueScreen(
              queues: FakeQueueService(),
              groups: FakeGroupService(),
            ),
          ),
        ),
        size: const Size(320, 568),
      );
      await goToReview(tester);
      expect(byKeyName('create-submit'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('acessibilidade e layout', () {
    testWidgets('barra de progresso anuncia o passo', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCreate(tester);
      expect(find.bySemanticsLabel('Passo 1 de 6'), findsOneWidget);
      await typeName(tester, 'Clínica');
      await tapKey(tester, 'create-continue');
      expect(find.bySemanticsLabel('Passo 2 de 6'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('botão de voltar tem rótulo e tooltip', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCreate(tester);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byTooltip('Voltar'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('todos os passos passam nos guidelines de toque', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpCreate(tester);
      await typeName(tester, 'Clínica');
      for (var i = 0; i < 5; i++) {
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await tapKey(tester, 'create-continue');
      }
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('modo hora marcada passa nos guidelines de toque', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpCreate(tester);
      await typeName(tester, 'Clínica');
      await tapKey(tester, 'create-continue');
      await tapKey(tester, 'create-mode-schedule');
      await tapKey(tester, 'create-suggest-60');
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('botão primário fica acima do teclado em 320x568', (
      tester,
    ) async {
      await pumpCreate(tester, size: const Size(320, 568));
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      final bottom = tester.getBottomLeft(byKeyName('create-continue')).dy;
      expect(bottom, lessThanOrEqualTo(568 - 260));
      expect(tester.takeException(), isNull);
    });

    testWidgets('20 horários em 320 px com texto 1.3x sem overflow', (
      tester,
    ) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: CreateQueueScreen(
              queues: FakeQueueService(),
              groups: FakeGroupService(),
            ),
          ),
        ),
        size: const Size(320, 568),
      );
      await typeName(tester, 'Clínica');
      await tapKey(tester, 'create-continue');
      await tapKey(tester, 'create-mode-schedule');
      await tapKey(tester, 'create-suggest-30');
      for (var i = 0; i < maxQueueSlots - 16; i++) {
        await tapKey(tester, 'slots-add');
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(maxQueueSlots));
      final add = tester.widget<OutlinedButton>(byKeyName('slots-add'));
      expect(add.onPressed, isNull);
      expect(tester.takeException(), isNull);

      await tapKey(tester, 'create-continue');
      expect(find.text('Há horários repetidos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('painel: botão de voltar tem rótulo', (tester) async {
    final handle = tester.ensureSemantics();
    final queues = FakeQueueService(
      queues: {'q1': fakeQueue('q1', name: 'Padaria')},
    );
    await pumpApp(
      tester,
      QueuePanelScreen(
        queueId: 'q1',
        queueName: 'Padaria',
        queues: queues,
        operators: FakeOperatorService(),
        groups: FakeGroupService(),
        showTour: false,
      ),
      size: const Size(390, 1800),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byTooltip('Voltar'), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
