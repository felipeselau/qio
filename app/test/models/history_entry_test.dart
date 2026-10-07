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

    test('recalls e skips padrao 0, numeros e clamp', () {
      final a = HistoryEntry.fromDoc('x', {});
      expect(a.recalls, 0);
      expect(a.skips, 0);
      final b = HistoryEntry.fromDoc('x', {'recalls': 2, 'skips': 3.0});
      expect(b.recalls, 2);
      expect(b.skips, 3);
      final c = HistoryEntry.fromDoc('x', {'recalls': -4, 'skips': -1});
      expect(c.recalls, 0);
      expect(c.skips, 0);
    });
  });
}
