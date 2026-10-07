import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/services/queue_analytics.dart';

HistoryEntry entryAt(int hour, {String result = 'served'}) => HistoryEntry(
  id: '$hour-$result',
  ticket: 1,
  name: 'x',
  result: result,
  joinedAt: DateTime(2026, 10, 1, hour, 30),
);

HistoryEntry joinedAt(DateTime t, [String id = 'e']) =>
    HistoryEntry(id: id, ticket: 1, name: 'x', result: 'served', joinedAt: t);

int matrixSum(List<List<int>> m) =>
    m.fold(0, (s, row) => s + row.fold(0, (a, b) => a + b));

void main() {
  group('demand', () {
    test('empty input gives zero 7 and 7x24 and no peak', () {
      expect(weekdayDistribution(const []), List<int>.filled(7, 0));
      final m = weekdayHourMatrix(const []);
      expect(m.length, 7);
      expect(m.every((r) => r.length == 24 && r.every((c) => c == 0)), isTrue);
      expect(peakCell(m), isNull);
    });

    test('23:59 Monday and 00:00 Tuesday land in distinct rows', () {
      final entries = [
        joinedAt(DateTime(2026, 10, 5, 23, 59), 'a'),
        joinedAt(DateTime(2026, 10, 6, 0, 0), 'b'),
      ];
      final m = weekdayHourMatrix(entries);
      expect(m[0][23], 1);
      expect(m[1][0], 1);
      expect(weekdayDistribution(entries).take(2), [1, 1]);
    });

    test('Sunday is index 6 and Monday index 0', () {
      final d = weekdayDistribution([
        joinedAt(DateTime(2026, 10, 4, 10), 'a'),
        joinedAt(DateTime(2026, 10, 5, 10), 'b'),
      ]);
      expect(d[6], 1);
      expect(d[0], 1);
    });

    test('matrix sum equals total and matches the weekday totals', () {
      final entries = [
        for (var i = 0; i < 40; i++)
          joinedAt(DateTime(2026, 10, 1 + i % 9, i % 24, 5), '$i'),
      ];
      final m = weekdayHourMatrix(entries);
      expect(matrixSum(m), 40);
      expect([
        for (final r in m) r.fold(0, (a, b) => a + b),
      ], weekdayDistribution(entries));
    });

    test('peakCell ties go to lower day then lower hour', () {
      final m = [for (var d = 0; d < 7; d++) List<int>.filled(24, 0)];
      m[4][18] = 5;
      m[2][20] = 5;
      m[2][9] = 5;
      m[6][1] = 4;
      final p = peakCell(m)!;
      expect((p.weekday, p.hour, p.count), (2, 9, 5));
      m[4][18] = 6;
      final q = peakCell(m)!;
      expect((q.weekday, q.hour, q.count), (4, 18, 6));
    });
  });

  test('hourlyDistribution buckets by join hour', () {
    final d = hourlyDistribution([entryAt(9), entryAt(9), entryAt(14)]);
    expect(d.length, 24);
    expect(d[9], 2);
    expect(d[14], 1);
    expect(d.reduce((a, b) => a + b), 3);
  });

  test('peakHours returns top hours by count, ties by earliest hour', () {
    final d = List<int>.filled(24, 0)
      ..[9] = 5
      ..[14] = 5
      ..[11] = 7
      ..[20] = 1;
    expect(peakHours(d), [11, 9, 14]);
    expect(peakHours(d, top: 1), [11]);
  });

  test('peakHours is empty when nothing happened', () {
    expect(peakHours(List<int>.filled(24, 0)), isEmpty);
  });

  test('rankByActivity sorts by total desc then name', () {
    HistoryMetrics m(int total) => HistoryMetrics(
      total: total,
      served: total,
      noShow: 0,
      left: 0,
      noShowRate: 0,
    );
    final ranked = rankByActivity([
      QueueActivity(queueId: 'a', name: 'Beta', metrics: m(2)),
      QueueActivity(queueId: 'b', name: 'Alfa', metrics: m(2)),
      QueueActivity(queueId: 'c', name: 'Zeta', metrics: m(9)),
    ]);
    expect(ranked.map((e) => e.queueId), ['c', 'b', 'a']);
  });
}
