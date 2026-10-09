import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/data_subject_service.dart';

void main() {
  group('normalizeCustomerPhone', () {
    test('keeps only digits and accepts 10 or 11', () {
      expect(normalizeCustomerPhone('(11) 99999-9999'), '11999999999');
      expect(normalizeCustomerPhone('11 3333-4444'), '1133334444');
      expect(normalizeCustomerPhone('1133334444'), '1133334444');
    });

    test('rejects short, long and empty input', () {
      for (final bad in ['', '123', '(11) 9999', '119999999999', 'abc']) {
        expect(normalizeCustomerPhone(bad), isNull, reason: bad);
      }
    });
  });

  group('customerPhoneForms', () {
    test('masks 11 and 10 digit numbers', () {
      expect(maskCustomerPhone('11999999999'), '(11) 99999-9999');
      expect(maskCustomerPhone('1133334444'), '(11) 3333-4444');
    });

    test('searches the masked and the digits-only forms', () {
      expect(customerPhoneForms('11999999999'), [
        '(11) 99999-9999',
        '11999999999',
      ]);
      expect(customerPhoneForms('1133334444'), [
        '(11) 3333-4444',
        '1133334444',
      ]);
    });
  });

  group('DataSubjectService', () {
    late List<(String, Map<String, dynamic>)> calls;

    DataSubjectService build(Map<String, dynamic> response) {
      calls = [];
      return DataSubjectService(
        invoker: (name, data) async {
          calls.add((name, data));
          return response;
        },
      );
    }

    test('find sends the digits and parses per-queue counts', () async {
      final service = build({
        'queues': [
          {
            'queueId': 'q1',
            'queueName': 'Balcão',
            'history': 2,
            'feedback': 1,
            'entries': 1,
            'firstAt': 1000,
            'lastAt': 2000,
          },
        ],
      });
      final summary = await service.find('11999999999');
      expect(calls.single.$1, 'findCustomerData');
      expect(calls.single.$2, {'phone': '11999999999'});
      expect(summary.queues.single.queueName, 'Balcão');
      expect(summary.history, 2);
      expect(summary.feedback, 1);
      expect(summary.entries, 1);
      expect(summary.total, 4);
      expect(summary.queues.single.firstAt, isNotNull);
      expect(summary.isEmpty, isFalse);
    });

    test('find with no queues is empty', () async {
      final summary = await build({'queues': []}).find('11999999999');
      expect(summary.isEmpty, isTrue);
    });

    test('erase sends the mode name and reads completeness', () async {
      final service = build({'queues': [], 'complete': false});
      final res = await service.erase('11999999999', CustomerEraseMode.delete);
      expect(calls.single.$1, 'eraseCustomerData');
      expect(calls.single.$2, {'phone': '11999999999', 'mode': 'delete'});
      expect(res.complete, isFalse);
      await service.erase('11999999999', CustomerEraseMode.anonymize);
      expect(calls.last.$2['mode'], 'anonymize');
    });

    test('export returns csv and truncated flag', () async {
      final service = build({'csv': 'a,b', 'truncated': true});
      final res = await service.export('11999999999');
      expect(calls.single.$1, 'exportCustomerData');
      expect(res.csv, 'a,b');
      expect(res.truncated, isTrue);
    });

    test('propagates invoker errors', () async {
      final service = DataSubjectService(
        invoker: (_, _) async => throw FirebaseException(
          plugin: 'cloud_functions',
          code: 'recent-login',
        ),
      );
      expect(service.find('11999999999'), throwsA(isA<FirebaseException>()));
    });
  });
}
