import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_slot.dart';
import 'package:qio_app/services/mirror.dart';

void main() {
  const uid = 'u1';
  final meta = {'name': 'Fila'};

  group('mirrorNeedsRepair', () {
    test('owner nulo precisa de reparo', () {
      expect(mirrorNeedsRepair(null, meta, uid), isTrue);
    });

    test('ownerUid diferente precisa de reparo', () {
      expect(mirrorNeedsRepair({'ownerUid': 'outro'}, meta, uid), isTrue);
    });

    test('meta nulo precisa de reparo', () {
      expect(mirrorNeedsRepair({'ownerUid': uid}, null, uid), isTrue);
    });

    test('espelho completo nao precisa de reparo', () {
      expect(mirrorNeedsRepair({'ownerUid': uid}, meta, uid), isFalse);
    });
  });

  group('mirrorModeSlotsPatch', () {
    const slots = [QueueSlot(id: 'a', start: '09:00', capacity: 2)];

    test('sem meta nao ha o que reconciliar', () {
      expect(mirrorModeSlotsPatch(null, QueueMode.schedule, slots), isNull);
    });

    test('meta sem mode equivale a queue sem slots', () {
      expect(mirrorModeSlotsPatch({'name': 'x'}, QueueMode.queue, []), isNull);
    });

    test('divergencia de mode gera patch', () {
      final patch = mirrorModeSlotsPatch(
        {'name': 'x'},
        QueueMode.schedule,
        slots,
      );
      expect(patch!['mode'], 'schedule');
      expect(patch['slots'], {
        'a': {'start': '09:00', 'capacity': 2},
      });
    });

    test('divergencia de slots gera patch mesmo com mode igual', () {
      final meta = {
        'mode': 'schedule',
        'slots': {
          'a': {'start': '09:30', 'capacity': 2},
        },
      };
      expect(mirrorModeSlotsPatch(meta, QueueMode.schedule, slots), isNotNull);
      final extra = {
        'mode': 'schedule',
        'slots': {
          'a': {'start': '09:00', 'capacity': 2},
          'z': {'start': '10:00', 'capacity': 1},
        },
      };
      expect(mirrorModeSlotsPatch(extra, QueueMode.schedule, slots), isNotNull);
    });

    test('espelho igual nao gera patch', () {
      final meta = {
        'mode': 'schedule',
        'slots': {
          'a': {'start': '09:00', 'capacity': 2},
        },
      };
      expect(mirrorModeSlotsPatch(meta, QueueMode.schedule, slots), isNull);
    });

    test(
      'volta para queue limpa o mode quando ha slots antigos no espelho',
      () {
        final meta = {'mode': 'schedule'};
        final patch = mirrorModeSlotsPatch(meta, QueueMode.queue, []);
        expect(patch!['mode'], 'queue');
        expect(patch['slots'], isNull);
      },
    );
  });
}
