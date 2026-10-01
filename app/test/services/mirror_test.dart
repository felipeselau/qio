import 'package:flutter_test/flutter_test.dart';
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
}
