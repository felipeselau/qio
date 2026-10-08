import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_entry.dart';
import 'package:qio_app/services/manual_entry_service.dart';
import 'package:qio_app/widgets/queue_panel/add_person_dialog.dart';

void main() {
  group('manualEntryErrorFrom', () {
    test('reason tem prioridade sobre o código', () {
      expect(
        manualEntryErrorFrom('resource-exhausted', 'queue-full'),
        ManualEntryError.queueFull,
      );
      expect(
        manualEntryErrorFrom('resource-exhausted', 'slot-full'),
        ManualEntryError.slotFull,
      );
      expect(
        manualEntryErrorFrom('invalid-argument', 'slot-required'),
        ManualEntryError.slotRequired,
      );
      expect(
        manualEntryErrorFrom('failed-precondition', 'slot-passed'),
        ManualEntryError.slotPassed,
      );
    });

    test('mapeia códigos sem reason', () {
      expect(
        manualEntryErrorFrom('failed-precondition', null),
        ManualEntryError.notOpen,
      );
      expect(
        manualEntryErrorFrom('invalid-argument', null),
        ManualEntryError.invalidInput,
      );
      expect(
        manualEntryErrorFrom('permission-denied', null),
        ManualEntryError.accessEnded,
      );
      expect(
        manualEntryErrorFrom('unavailable', null),
        ManualEntryError.offline,
      );
      expect(manualEntryErrorFrom('internal', null), ManualEntryError.generic);
    });
  });

  group('formatBrPhone', () {
    test('aplica a máscara de 10 e 11 dígitos', () {
      expect(formatBrPhone(''), '');
      expect(formatBrPhone('1'), '(1');
      expect(formatBrPhone('11'), '(11');
      expect(formatBrPhone('1191'), '(11) 91');
      expect(formatBrPhone('1133334444'), '(11) 3333-4444');
      expect(formatBrPhone('11912345678'), '(11) 91234-5678');
      expect(formatBrPhone('1191234567899'), '(11) 91234-5678');
    });

    test('isValidManualPhone aceita vazio e máscara completa', () {
      expect(isValidManualPhone(''), isTrue);
      expect(isValidManualPhone('(11) 91234-5678'), isTrue);
      expect(isValidManualPhone('(11) 3333-4444'), isTrue);
      expect(isValidManualPhone('(11) 9123'), isFalse);
    });
  });

  group('QueueEntry manual', () {
    test('lê manual e tolera uid ausente', () {
      final e = QueueEntry.fromSnapshot('m1', {
        'ticket': 3,
        'name': 'Maria',
        'phone': '',
        'status': 'waiting',
        'joinedAt': 1000,
        'manual': true,
      });
      expect(e.manual, isTrue);
      expect(e.uid, '');
    });

    test('entry de cliente não é manual', () {
      final e = QueueEntry.fromSnapshot('c1', {
        'ticket': 3,
        'name': 'Ana',
        'uid': 'u1',
        'status': 'waiting',
      });
      expect(e.manual, isFalse);
    });
  });
}
