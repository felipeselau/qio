import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/history_entry.dart';

void main() {
  group('HistoryEntry.fromDoc', () {
    test('le calledBy e operatorId', () {
      final e = HistoryEntry.fromDoc('x', {
        'result': 'served',
        'calledBy': 'a',
        'operatorId': 'b',
      });
      expect(e.calledBy, 'a');
      expect(e.operatorId, 'b');
      expect(e.attendantId, 'a');
    });

    test('attendantId cai para operatorId e depois null', () {
      expect(HistoryEntry.fromDoc('x', {'operatorId': 'b'}).attendantId, 'b');
      expect(HistoryEntry.fromDoc('x', {}).attendantId, isNull);
      expect(
        HistoryEntry.fromDoc('x', {
          'calledBy': '',
          'operatorId': '',
        }).attendantId,
        isNull,
      );
    });
  });
}
