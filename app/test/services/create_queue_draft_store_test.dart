import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/controllers/create_queue_controller.dart';
import 'package:qio_app/controllers/create_queue_draft.dart';
import 'package:qio_app/services/create_queue_draft_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_draft_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SharedPrefsCreateQueueDraftStore', () {
    const store = SharedPrefsCreateQueueDraftStore();

    test('chave por uid', () {
      expect(createQueueDraftKey('u1'), 'create_queue_draft_u1');
    });

    test('load devolve null sem rascunho', () async {
      expect(await store.load('u1'), isNull);
    });

    test('save e load fazem round-trip com o controller', () async {
      final c = CreateQueueController(
        draft: const CreateQueueDraft(name: 'Padaria', avgServiceMin: '15'),
        step: CreateQueueStep.capacity,
      );
      await store.save('u1', c.toJson());

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('create_queue_draft_u1'), isNotNull);

      final restored = CreateQueueController.fromJson(await store.load('u1'));
      expect(restored!.draft.name, 'Padaria');
      expect(restored.draft.avgServiceMin, '15');
      expect(restored.step, CreateQueueStep.capacity);
    });

    test('rascunhos são isolados por uid e clear remove só o do uid', () async {
      await store.save('u1', const CreateQueueDraft(name: 'A').toJson());
      await store.save('u2', const CreateQueueDraft(name: 'B').toJson());
      await store.clear('u1');
      expect(await store.load('u1'), isNull);
      expect((await store.load('u2') as Map)['name'], 'B');
    });

    test('JSON corrompido vira null e é apagado', () async {
      SharedPreferences.setMockInitialValues({
        'create_queue_draft_u1': '{nao e json',
      });
      expect(await store.load('u1'), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('create_queue_draft_u1'), isFalse);
    });

    test('versão futura é rejeitada pelo controller', () async {
      await store.save('u1', {
        ...const CreateQueueDraft(name: 'X').toJson(),
        'version': createQueueDraftVersion + 1,
      });
      expect(CreateQueueController.fromJson(await store.load('u1')), isNull);
    });
  });

  group('FakeCreateQueueDraftStore', () {
    test('salva, carrega e limpa em memória', () async {
      final store = FakeCreateQueueDraftStore();
      expect(await store.load('u1'), isNull);
      await store.save('u1', const CreateQueueDraft(name: 'A').toJson());
      expect((await store.load('u1') as Map)['name'], 'A');
      await store.clear('u1');
      expect(await store.load('u1'), isNull);
      expect(store.calls, [
        'load:u1',
        'save:u1',
        'load:u1',
        'clear:u1',
        'load:u1',
      ]);
    });
  });
}
