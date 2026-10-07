import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_feedback.dart';
import 'package:qio_app/models/queue_group.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/services/metrics_export.dart';
import 'package:qio_app/services/queue_analytics.dart';

final now = DateTime(2026, 10, 7, 12);

Queue queue(String id, {String? groupId}) => Queue(
  id: id,
  ownerId: 'own',
  name: 'Fila $id',
  createdAt: DateTime(2026, 1, 1),
  groupId: groupId,
);

HistoryEntry entry(String id, {String result = 'served', int waitMin = 5}) {
  final joined = DateTime(2026, 10, 7, 9);
  final called = joined.add(Duration(minutes: waitMin));
  return HistoryEntry(
    id: id,
    ticket: 1,
    name: 'n$id',
    result: result,
    joinedAt: joined,
    calledAt: called,
    finishedAt: called.add(const Duration(minutes: 10)),
  );
}

QueueHistoryInput input(
  Queue q,
  List<HistoryEntry> entries, [
  List<QueueFeedback> feedback = const [],
]) => QueueHistoryInput(q, entries, feedback, const []);

QueueGroup grp(String id) =>
    QueueGroup(id: id, name: 'G$id', createdAt: DateTime(2026));

void main() {
  final groups = [grp('g1'), grp('g2')];
  final data = [
    input(queue('a', groupId: 'g1'), [entry('1')]),
    input(queue('b', groupId: 'g1'), [entry('2'), entry('3')]),
    input(queue('c', groupId: 'g2'), [entry('4')]),
    input(queue('d'), [entry('5')]),
    input(queue('e', groupId: 'gone'), [entry('6')]),
  ];

  List<String> ids(List<QueueHistoryInput> d) => [
    for (final i in d) i.queue.id,
  ];

  group('filterByScope', () {
    test('all keeps every queue', () {
      expect(ids(filterByScope(data, groups, MetricsScope.all)), [
        'a',
        'b',
        'c',
        'd',
        'e',
      ]);
    });

    test('group keeps only its queues', () {
      expect(ids(filterByScope(data, groups, const MetricsScope.group('g1'))), [
        'a',
        'b',
      ]);
      expect(ids(filterByScope(data, groups, const MetricsScope.group('g2'))), [
        'c',
      ]);
    });

    test('queue keeps a single queue', () {
      expect(ids(filterByScope(data, groups, const MetricsScope.queue('d'))), [
        'd',
      ]);
    });

    test('orphan groupId and ungrouped queues belong to no group', () {
      for (final g in ['g1', 'g2', 'gone']) {
        final r = filterByScope(data, groups, MetricsScope.group(g));
        expect(ids(r).contains('d'), isFalse);
        expect(ids(r).contains('e'), isFalse);
      }
      expect(
        ids(filterByScope(data, groups, const MetricsScope.group('gone'))),
        isEmpty,
      );
    });

    test('unknown queue or group yields empty', () {
      expect(
        filterByScope(data, groups, const MetricsScope.queue('zzz')),
        isEmpty,
      );
      expect(
        filterByScope(data, groups, const MetricsScope.group('zzz')),
        isEmpty,
      );
    });

    test('scope equality', () {
      expect(const MetricsScope.group('g1'), const MetricsScope.group('g1'));
      expect(
        const MetricsScope.group('g1') == const MetricsScope.queue('g1'),
        isFalse,
      );
    });

    test('filtered data feeds the report totals', () {
      final r = buildMetricsReport(
        data: filterByScope(data, groups, const MetricsScope.group('g1')),
        period: HistoryPeriod.all,
        now: now,
        historyLimit: 500,
        unknownOperatorName: 'ex',
      );
      expect(r.metrics.total, 3);
    });
  });

  group('compareQueues', () {
    test('per queue totals, wait, no-show rate and rating', () {
      final g1 = filterByScope(data, groups, const MetricsScope.group('g1'));
      final withFeedback = [
        input(g1[0].queue, g1[0].entries, const [
          QueueFeedback(entryId: '1', rating: 5),
        ]),
        input(
          g1[1].queue,
          [entry('2'), entry('3', result: 'no_show', waitMin: 15)],
          const [QueueFeedback(entryId: '2', rating: 3)],
        ),
      ];
      final rows = compareQueues(
        withFeedback,
        period: HistoryPeriod.all,
        now: now,
      );
      expect(rows.map((r) => r.queueId), ['b', 'a']);
      expect(rows[0].metrics.total, 2);
      expect(rows[0].metrics.noShowRate, 0.5);
      expect(rows[0].feedback.average, 3);
      expect(rows[1].metrics.total, 1);
      expect(rows[1].metrics.avgWaitMin, 5);
      expect(rows[1].feedback.count, 1);
      expect(rows[1].feedback.average, 5);
    });

    test('queue without feedback has no rating', () {
      final rows = compareQueues(
        [data[0]],
        period: HistoryPeriod.all,
        now: now,
      );
      expect(rows.single.feedback.average, isNull);
    });
  });

  group('export scope label', () {
    final pt = lookupAppLocalizations(const Locale('pt'));

    MetricsReport report(String? label) => buildMetricsReport(
      data: data,
      period: HistoryPeriod.all,
      now: now,
      historyLimit: 500,
      unknownOperatorName: 'ex',
      scopeLabel: label,
    );

    test('csv header carries the scope when set', () {
      final csv = buildMetricsCsv(
        pt,
        report('Grupo: Loja'),
        generatedAt: DateTime(2026, 10, 7),
      );
      expect(csv, contains('${pt.csvDataScope},Grupo: Loja'));
    });

    test('csv header omits the scope when unset', () {
      final csv = buildMetricsCsv(
        pt,
        report(null),
        generatedAt: DateTime(2026, 10, 7),
      );
      expect(csv, isNot(contains(pt.csvDataScope)));
    });
  });
}
