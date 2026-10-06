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

void main() {
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
