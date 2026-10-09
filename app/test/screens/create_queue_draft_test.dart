import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/controllers/create_queue_controller.dart';
import 'package:qio_app/controllers/create_queue_draft.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_group.dart';
import 'package:qio_app/screens/create_queue_screen.dart';

import '../helpers/create_queue_flow.dart';
import '../helpers/fake_draft_store.dart';
import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

const uid = 'u1';

Map<String, Object?> draftJson({
  String name = 'Padaria',
  CreateQueueStep step = CreateQueueStep.capacity,
  String avg = '',
  String? groupId,
}) => CreateQueueController(
  draft: CreateQueueDraft(name: name, avgServiceMin: avg, groupId: groupId),
  step: step,
).toJson();

Future<void> openFromLauncher(
  WidgetTester tester, {
  required FakeCreateQueueDraftStore store,
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
              draftStore: store,
              uid: uid,
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
  group('salvar', () {
    testWidgets('Continuar grava o rascunho; digitar não grava', (
      tester,
    ) async {
      final store = FakeCreateQueueDraftStore();
      await pumpCreate(tester, draftStore: store, uid: uid);
      await typeName(tester, 'Clínica');
      expect(store.calls, ['load:$uid']);

      await tapKey(tester, 'create-continue');
      expect(store.calls, ['load:$uid', 'save:$uid']);
      final saved = store.data[uid]! as Map;
      expect(saved['name'], 'Clínica');
      expect(saved['step'], 'mode');

      await tapKey(tester, 'create-back');
      expect(store.calls.last, 'save:$uid');
      expect(store.calls.where((c) => c.startsWith('save')).length, 2);
    });

    testWidgets('pausar o app grava o rascunho sujo', (tester) async {
      final store = FakeCreateQueueDraftStore();
      await pumpCreate(tester, draftStore: store, uid: uid);
      await typeName(tester, 'Clínica');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect((store.data[uid]! as Map)['name'], 'Clínica');
    });

    testWidgets('sem uid nada é persistido', (tester) async {
      final store = FakeCreateQueueDraftStore();
      await pumpCreate(tester, draftStore: store, uid: '');
      await typeName(tester, 'Clínica');
      await tapKey(tester, 'create-continue');
      expect(store.calls, isEmpty);
    });
  });

  group('retomar', () {
    testWidgets('Continuar restaura campos e passo', (tester) async {
      final store = FakeCreateQueueDraftStore(
        initial: {uid: draftJson(avg: '25')},
      );
      await pumpCreate(tester, draftStore: store, uid: uid);
      await tester.pumpAndSettle();
      expect(find.text('Continuar de onde parou?'), findsOneWidget);

      await tapKey(tester, 'create-resume-continue');
      expect(find.text('Continuar de onde parou?'), findsNothing);
      expect(byKeyName('create-avg'), findsOneWidget);
      expect(textOf(tester, 'create-avg'), '25');

      await tapKey(tester, 'create-back');
      await tapKey(tester, 'create-back');
      expect(textOf(tester, 'create-name'), 'Padaria');
    });

    testWidgets('Descartar apaga e segue do zero', (tester) async {
      final store = FakeCreateQueueDraftStore(initial: {uid: draftJson()});
      await pumpCreate(tester, draftStore: store, uid: uid);
      await tester.pumpAndSettle();

      await tapKey(tester, 'create-resume-discard');
      expect(store.data, isEmpty);
      expect(byKeyName('create-name'), findsOneWidget);
      expect(textOf(tester, 'create-name'), '');
    });

    testWidgets('rascunho de outro uid é ignorado', (tester) async {
      final store = FakeCreateQueueDraftStore(initial: {'outro': draftJson()});
      await pumpCreate(tester, draftStore: store, uid: uid);
      await tester.pumpAndSettle();
      expect(find.text('Continuar de onde parou?'), findsNothing);
      expect(store.data.containsKey('outro'), isTrue);
    });

    for (final entry in {
      'lixo': 'texto',
      'versão futura': {...draftJson(), 'version': createQueueDraftVersion + 1},
      'versão antiga': {...draftJson(), 'version': 0},
      'vazio': const CreateQueueDraft().toJson(),
      'mapa sem versão': <String, Object?>{'name': 'x'},
    }.entries) {
      testWidgets('rascunho inválido (${entry.key}) é ignorado e apagado', (
        tester,
      ) async {
        final store = FakeCreateQueueDraftStore(initial: {uid: entry.value});
        await pumpCreate(tester, draftStore: store, uid: uid);
        await tester.pumpAndSettle();

        expect(find.text('Continuar de onde parou?'), findsNothing);
        expect(store.data, isEmpty);
        expect(tester.takeException(), isNull);
        expect(byKeyName('create-name'), findsOneWidget);
      });
    }

    testWidgets('grupo que não existe mais é descartado ao restaurar', (
      tester,
    ) async {
      final store = FakeCreateQueueDraftStore(
        initial: {
          uid: draftJson(groupId: 'sumiu', step: CreateQueueStep.mode),
          'u2': draftJson(groupId: 'g1', step: CreateQueueStep.mode),
        },
      );
      final groups = FakeGroupService(
        groups: [QueueGroup(id: 'g1', name: 'Loja', createdAt: DateTime(2026))],
      );
      final queues = FakeQueueService();
      await pumpCreate(
        tester,
        queues: queues,
        draftStore: store,
        uid: uid,
        groups: groups,
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'create-resume-continue');
      await tapKey(tester, 'create-back');
      await tapKey(tester, 'create-quick');
      expect(queues.createdArgs!.groupId, isNull);
    });

    testWidgets('grupo que ainda existe é mantido ao restaurar', (
      tester,
    ) async {
      final store = FakeCreateQueueDraftStore(
        initial: {uid: draftJson(groupId: 'g1', step: CreateQueueStep.mode)},
      );
      final groups = FakeGroupService(
        groups: [QueueGroup(id: 'g1', name: 'Loja', createdAt: DateTime(2026))],
      );
      final queues = FakeQueueService();
      await pumpCreate(
        tester,
        queues: queues,
        draftStore: store,
        uid: uid,
        groups: groups,
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'create-resume-continue');
      await tapKey(tester, 'create-back');
      await tapKey(tester, 'create-quick');
      expect(queues.createdArgs!.groupId, 'g1');
    });
  });

  group('limpar', () {
    testWidgets('sucesso limpa o rascunho antes de navegar', (tester) async {
      final store = FakeCreateQueueDraftStore();
      final clearGate = Completer<void>();
      final queues = FakeQueueService()
        ..createResult = Queue(
          id: 'q1',
          ownerId: uid,
          name: 'Padaria',
          createdAt: DateTime(2026),
        );
      await openFromLauncher(tester, store: store, queues: queues);
      await typeName(tester, 'Padaria');
      await tapKey(tester, 'create-continue');
      await tapKey(tester, 'create-back');
      expect(store.data.containsKey(uid), isTrue);

      store.clearGate = clearGate.future;
      await tester.tap(byKeyName('create-quick'));
      await tester.pump();
      await tester.pump();
      expect(queues.calls, ['create:Padaria:queue:0']);
      expect(store.calls.last, 'clear:$uid');
      expect(byKeyName('create-name'), findsOneWidget);
      expect(store.data.containsKey(uid), isTrue);
    });

    testWidgets('falha na criação mantém o rascunho', (tester) async {
      final store = FakeCreateQueueDraftStore();
      final queues = FakeQueueService()..createError = Exception('boom');
      await pumpCreate(tester, queues: queues, draftStore: store, uid: uid);
      await typeName(tester, 'Padaria');
      await tapKey(tester, 'create-continue');
      await tapKey(tester, 'create-back');
      await tapKey(tester, 'create-quick');

      expect(byKeyName('create-error'), findsOneWidget);
      expect(store.data.containsKey(uid), isTrue);
    });
  });

  group('sair', () {
    testWidgets('Salvar rascunho grava e sai', (tester) async {
      final store = FakeCreateQueueDraftStore();
      await openFromLauncher(tester, store: store);
      await typeName(tester, 'Algo');
      await tapKey(tester, 'create-back');
      expect(find.text('Salvar rascunho'), findsOneWidget);

      await tester.tap(find.text('Salvar rascunho'));
      await tester.pumpAndSettle();
      expect(find.text('abrir'), findsOneWidget);
      expect((store.data[uid]! as Map)['name'], 'Algo');
    });

    testWidgets('Descartar apaga o rascunho e sai', (tester) async {
      final store = FakeCreateQueueDraftStore(
        initial: {uid: draftJson(step: CreateQueueStep.name)},
      );
      await openFromLauncher(tester, store: store);
      await tapKey(tester, 'create-resume-continue');
      await typeName(tester, 'Mudou');
      await tapKey(tester, 'create-back');

      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      expect(find.text('abrir'), findsOneWidget);
      expect(store.data, isEmpty);
    });

    testWidgets('rascunho já salvo sai sem perguntar', (tester) async {
      final store = FakeCreateQueueDraftStore();
      await openFromLauncher(tester, store: store);
      await typeName(tester, 'Algo');
      await tapKey(tester, 'create-continue');
      await tapKey(tester, 'create-back');
      await tapKey(tester, 'create-back');

      expect(find.text('Descartar alterações?'), findsNothing);
      expect(find.text('abrir'), findsOneWidget);
      expect((store.data[uid]! as Map)['name'], 'Algo');
    });

    testWidgets('Continuar editando mantém tela e rascunho', (tester) async {
      final store = FakeCreateQueueDraftStore();
      await openFromLauncher(tester, store: store);
      await typeName(tester, 'Algo');
      await tapKey(tester, 'create-back');
      await tester.tap(find.text('Continuar editando'));
      await tester.pumpAndSettle();
      expect(byKeyName('create-name'), findsOneWidget);
      expect(store.data, isEmpty);
    });

    testWidgets('durante o envio o voltar não abre diálogo', (tester) async {
      final store = FakeCreateQueueDraftStore();
      final gate = Completer<void>();
      final queues = FakeQueueService()..createGate = gate.future;
      await openFromLauncher(tester, store: store, queues: queues);
      await typeName(tester, 'Padaria');
      await tester.tap(byKeyName('create-quick'));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Descartar alterações?'), findsNothing);
      gate.complete();
      await tester.pumpAndSettle();
    });
  });
}
