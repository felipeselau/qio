import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/models/operator.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_feedback.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/services/metrics_export.dart';

final now = DateTime(2026, 10, 7, 12);

Queue queue(String id, {String? name, String ownerId = 'own'}) => Queue(
  id: id,
  ownerId: ownerId,
  name: name ?? 'Fila $id',
  createdAt: DateTime(2026, 1, 1),
);

HistoryEntry served(
  String id, {
  DateTime? joinedAt,
  int serviceMin = 10,
  String? calledBy,
  String result = 'served',
}) {
  final joined = joinedAt ?? DateTime(2026, 10, 7, 9);
  final called = joined.add(const Duration(minutes: 5));
  return HistoryEntry(
    id: id,
    ticket: 1,
    name: 'n$id',
    result: result,
    joinedAt: joined,
    calledAt: called,
    finishedAt: called.add(Duration(minutes: serviceMin)),
    calledBy: calledBy,
  );
}

QueueOperator op(String uid, String name) =>
    QueueOperator(uid: uid, queueId: 'a', queueName: 'A', displayName: name);

MetricsReport report(
  List<QueueHistoryInput> data, {
  HistoryPeriod period = HistoryPeriod.all,
  String? queueId,
  int limit = 500,
}) => buildMetricsReport(
  data: data,
  period: period,
  now: now,
  historyLimit: limit,
  unknownOperatorName: 'ex',
  operatorQueueId: queueId,
);

void main() {
  group('buildMetricsReport', () {
    test('filters by period', () {
      final old = served('old', joinedAt: DateTime(2026, 9, 1, 9));
      final recent = served('new');
      final data = [
        QueueHistoryInput(queue('a'), [old, recent], const [], const []),
      ];
      expect(report(data).metrics.total, 2);
      final r = report(data, period: HistoryPeriod.last7Days);
      expect(r.metrics.total, 1);
      expect(r.isEmpty, isFalse);
      expect(r.peaks, [9]);
      expect(r.distribution[9], 1);
    });

    test('queue selector only affects operators', () {
      final data = [
        QueueHistoryInput(
          queue('a', ownerId: 'o1'),
          [served('1'), served('2', calledBy: 'u1')],
          const [],
          [op('u1', 'Bia')],
        ),
        QueueHistoryInput(
          queue('b', ownerId: 'o2'),
          [served('3'), served('4'), served('5')],
          const [],
          const [],
        ),
      ];
      final all = report(data);
      expect(all.metrics.total, 5);
      expect(all.operators.fold<int>(0, (s, o) => s + o.served), 5);
      expect(all.operatorQueueName, isNull);
      final onlyA = report(data, queueId: 'a');
      expect(onlyA.metrics.total, 5);
      expect(onlyA.ranking.length, 2);
      expect(onlyA.operators.fold<int>(0, (s, o) => s + o.served), 2);
      expect(onlyA.operatorQueueName, 'Fila a');
      expect(onlyA.operatorNames['u1'], 'Bia');
    });

    test('operator feedback follows selected queue', () {
      final data = [
        QueueHistoryInput(
          queue('a'),
          [served('1')],
          const [QueueFeedback(entryId: '1', rating: 4)],
          const [],
        ),
      ];
      final r = report(data);
      expect(r.operators.single.feedback.count, 1);
      expect(r.operators.single.feedback.average, 4);
    });

    test('flags truncation only when oldest entry is inside the period', () {
      final entries = [
        served('1'),
        served('2', joinedAt: DateTime(2026, 10, 6, 9)),
      ];
      final data = [QueueHistoryInput(queue('a'), entries, const [], const [])];
      expect(report(data, limit: 2).truncated, isTrue);
      expect(report(data, limit: 3).truncated, isFalse);
      final older = [
        served('1'),
        served('2', joinedAt: DateTime(2026, 8, 1, 9)),
      ];
      final data2 = [QueueHistoryInput(queue('a'), older, const [], const [])];
      expect(
        report(data2, period: HistoryPeriod.last7Days, limit: 2).truncated,
        isFalse,
      );
    });

    test('truncation respects the queue selector', () {
      final full = [served('1'), served('2')];
      final data = [
        QueueHistoryInput(queue('a'), full, const [], const []),
        QueueHistoryInput(queue('b'), [served('3')], const [], const []),
      ];
      expect(report(data, limit: 2).truncated, isTrue);
      expect(report(data, limit: 2, queueId: 'b').truncated, isFalse);
    });

    test('empty data', () {
      final r = report([
        QueueHistoryInput(queue('a'), const [], const [], const []),
      ]);
      expect(r.isEmpty, isTrue);
      expect(r.metrics.total, 0);
      expect(r.peaks, isEmpty);
      expect(r.operators, isEmpty);
      expect(r.truncated, isFalse);
      expect(r.ranking.single.name, 'Fila a');
      expect(report(const []).isEmpty, isTrue);
    });
  });
}
