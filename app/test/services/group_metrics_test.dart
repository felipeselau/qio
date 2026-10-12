import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_feedback.dart';
import 'package:qio_app/models/queue_group.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/services/metrics_export.dart';
import 'package:qio_app/services/metrics_trend.dart';
import 'package:qio_app/services/queue_analytics.dart';
import 'package:qio_app/services/queue_service.dart';

final now = DateTime(2026, 10, 7, 12);

Queue queue(String id, {String? groupId}) => Queue(
  id: id,
  ownerId: 'own',
  name: 'Fila $id',
  createdAt: DateTime(2026, 1, 1),
  groupId: groupId,
);

QueueGroup grp(String id, {String? name}) =>
    QueueGroup(id: id, name: name ?? 'G$id', createdAt: DateTime(2026));

HistoryEntry e(
  String id,
  DateTime finishedAt, {
  String result = 'served',
  int waitMin = 5,
  String? phone,
}) {
  final called = finishedAt.subtract(const Duration(minutes: 10));
  return HistoryEntry(
    id: id,
    ticket: 1,
    name: 'n$id',
    phone: phone,
    result: result,
    joinedAt: called.subtract(Duration(minutes: waitMin)),
    calledAt: called,
    finishedAt: finishedAt,
  );
}

QueueHistoryInput input(
  Queue q,
  List<HistoryEntry> entries, [
  List<QueueFeedback> feedback = const [],
]) => QueueHistoryInput(q, entries, feedback, const []);

final today = DateTime(2026, 10, 7, 10);
final lastWeek = DateTime(2026, 9, 30, 10);

List<GroupComparison> groupsOf(
  List<QueueHistoryInput> data,
  List<QueueGroup> groups, {
  HistoryPeriod period = HistoryPeriod.last7Days,
  DateRange? custom,
  int limit = 500,
}) => compareGroups(
  data,
  groups,
  period: period,
  now: now,
  custom: custom,
  historyLimit: limit,
);

void main() {
  setUpAll(initializeDateFormatting);

  test('default history limit matches the service fetch limit', () {
    expect(defaultHistoryLimit, QueueService.historyFetchLimit);
  });

  group('scope ungrouped', () {
    final groups = [grp('g1')];
    final data = [
      input(queue('a', groupId: 'g1'), [e('1', today)]),
      input(queue('b'), [e('2', today)]),
      input(queue('c', groupId: 'gone'), [e('3', today)]),
    ];

    test('filters queues without a valid group', () {
      final r = filterByScope(data, groups, MetricsScope.ungrouped);
      expect(r.map((d) => d.queue.id), ['b', 'c']);
    });

    test('sanitize keeps it only while there is an ungrouped queue', () {
      expect(
        sanitizeScope(MetricsScope.ungrouped, data, groups),
        MetricsScope.ungrouped,
      );
      expect(
        sanitizeScope(MetricsScope.ungrouped, [data[0]], groups),
        MetricsScope.all,
      );
    });
  });

  group('compareGroups', () {
    test('one row per group plus Sem grupo, empty group disappears', () {
      final groups = [grp('g1'), grp('g2'), grp('g3')];
      final rows = groupsOf([
        input(queue('a', groupId: 'g1'), [e('1', today)]),
        input(queue('b', groupId: 'g1'), [e('2', today), e('3', today)]),
        input(queue('c', groupId: 'g2'), const []),
        input(queue('d'), [e('4', today)]),
      ], groups);
      expect(rows.map((r) => r.groupId), ['g1', null, 'g2']);
      expect(rows[0].queueCount, 2);
      expect(rows[0].metrics.total, 3);
      expect(rows[1].groupId, isNull);
      expect(rows[2].metrics.total, 0);
    });

    test('orphan groupId counts as Sem grupo', () {
      final rows = groupsOf(
        [
          input(queue('a', groupId: 'gone'), [e('1', today)]),
          input(queue('b'), [e('2', today)]),
        ],
        [grp('g1')],
      );
      expect(rows, hasLength(1));
      expect(rows.single.groupId, isNull);
      expect(rows.single.queueCount, 2);
      expect(rows.single.metrics.total, 2);
    });

    test('no groups defined puts everything in Sem grupo', () {
      final rows = groupsOf([
        input(queue('a'), [e('1', today)]),
      ], const []);
      expect(rows.single.groupId, isNull);
    });

    test('empty data gives no rows', () {
      expect(groupsOf(const [], [grp('g1')]), isEmpty);
    });

    test('sorts by volume and keeps Sem grupo last on ties', () {
      final rows = groupsOf(
        [
          input(queue('a'), [e('1', today)]),
          input(queue('b', groupId: 'g1'), [e('2', today)]),
          input(queue('c', groupId: 'g2'), [e('3', today), e('4', today)]),
        ],
        [grp('g1'), grp('g2')],
      );
      expect(rows.map((r) => r.groupId), ['g2', 'g1', null]);
    });

    test('aggregates wait stats, rating and no-show across queues', () {
      final rows = groupsOf(
        [
          input(
            queue('a', groupId: 'g1'),
            [e('1', today, waitMin: 2), e('2', today, waitMin: 4)],
            const [QueueFeedback(entryId: '1', rating: 5)],
          ),
          input(
            queue('b', groupId: 'g1'),
            [e('3', today, waitMin: 6), e('4', today, result: 'no_show')],
            const [
              QueueFeedback(entryId: '3', rating: 3),
              QueueFeedback(entryId: 'old', rating: 1),
            ],
          ),
        ],
        [grp('g1')],
      );
      final r = rows.single;
      expect(r.metrics.total, 4);
      expect(r.metrics.noShowRate, 0.25);
      expect(r.waitStats.samples, 4);
      expect(r.waitStats.medianMin, 4.5);
      expect(r.feedback.count, 2);
      expect(r.feedback.average, 4);
      expect(r.partial, isFalse);
    });

    test('variation compares with the previous period', () {
      final rows = groupsOf(
        [
          input(queue('a', groupId: 'g1'), [
            e('1', today),
            e('2', today),
            e('3', lastWeek),
          ]),
        ],
        [grp('g1')],
      );
      expect(rows.single.deltas[MetricKey.total]!.pct, 100);
      expect(rows.single.deltas, contains(MetricKey.noShowRate));
    });

    test('no variation without previous data or for all time', () {
      final data = [
        input(queue('a', groupId: 'g1'), [e('1', today)]),
      ];
      expect(groupsOf(data, [grp('g1')]).single.deltas, isEmpty);
      final allTime = groupsOf(
        [
          input(queue('a', groupId: 'g1'), [e('1', today), e('2', lastWeek)]),
        ],
        [grp('g1')],
        period: HistoryPeriod.all,
      );
      expect(allTime.single.deltas, isEmpty);
      expect(allTime.single.metrics.total, 2);
    });

    test('custom period uses its range and its previous window', () {
      final range = customRangeFromPicked(
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 6),
      );
      final rows = groupsOf(
        [
          input(queue('a', groupId: 'g1'), [
            e('1', DateTime(2026, 10, 5, 10)),
            e('2', DateTime(2026, 10, 6, 10)),
            e('3', DateTime(2026, 10, 6, 11)),
            e('4', DateTime(2026, 10, 7, 10)),
            e('5', DateTime(2026, 10, 4, 10)),
          ]),
        ],
        [grp('g1')],
        period: HistoryPeriod.custom,
        custom: range,
      );
      expect(rows.single.metrics.total, 3);
      expect(rows.single.deltas[MetricKey.total]!.pct, 200);
    });

    test('custom period without range yields empty totals', () {
      final rows = groupsOf(
        [
          input(queue('a', groupId: 'g1'), [e('1', today)]),
        ],
        [grp('g1')],
        period: HistoryPeriod.custom,
      );
      expect(rows.single.metrics.total, 0);
      expect(rows.single.deltas, isEmpty);
    });

    test('truncated queue marks the group partial and drops variation', () {
      final rows = groupsOf(
        [
          input(queue('a', groupId: 'g1'), [
            e('1', today),
            e('2', today),
            e('3', DateTime(2026, 10, 2, 10)),
          ]),
          input(queue('b', groupId: 'g1'), [e('4', today), e('5', lastWeek)]),
        ],
        [grp('g1')],
        limit: 3,
      );
      expect(rows.single.partial, isTrue);
      expect(rows.single.deltas, isEmpty);
      expect(rows.single.metrics.total, 4);
    });

    test('limit reached but oldest entry before the period is complete', () {
      final rows = groupsOf(
        [
          input(queue('a', groupId: 'g1'), [
            e('1', today),
            e('2', today),
            e('3', lastWeek),
            e('4', DateTime(2026, 9, 1, 10)),
          ]),
        ],
        [grp('g1')],
        limit: 4,
      );
      expect(rows.single.partial, isFalse);
      expect(rows.single.deltas, isNotEmpty);
    });

    test('previous window possibly cut gives no variation but no flag', () {
      final rows = groupsOf(
        [
          input(queue('a', groupId: 'g1'), [
            e('1', today),
            e('2', today),
            e('3', lastWeek),
          ]),
        ],
        [grp('g1')],
        limit: 3,
      );
      expect(rows.single.partial, isFalse);
      expect(rows.single.deltas, isEmpty);
    });

    test('is deterministic with the injected clock', () {
      final data = [
        input(queue('a', groupId: 'g1'), [e('1', today)]),
      ];
      final later = compareGroups(
        data,
        [grp('g1')],
        period: HistoryPeriod.today,
        now: DateTime(2026, 10, 9, 12),
      );
      expect(later.single.metrics.total, 0);
    });
  });

  group('compareQueues enriched', () {
    test('exposes wait stats and variation', () {
      final rows = compareQueues(
        [
          input(queue('a'), [
            e('1', today, waitMin: 2),
            e('2', today, waitMin: 8),
            e('3', lastWeek, waitMin: 4),
          ]),
        ],
        period: HistoryPeriod.last7Days,
        now: now,
      );
      final r = rows.single;
      expect(r.waitStats.samples, 2);
      expect(r.waitStats.medianMin, 5);
      expect(r.deltas[MetricKey.total]!.pct, 100);
      expect(r.deltas[MetricKey.waitMedian]!.pct, 25);
      expect(r.partial, isFalse);
    });

    test('truncated queue is partial without variation', () {
      final rows = compareQueues(
        [
          input(queue('a'), [e('1', today), e('2', today), e('3', today)]),
        ],
        period: HistoryPeriod.last7Days,
        now: now,
        historyLimit: 3,
      );
      expect(rows.single.partial, isTrue);
      expect(rows.single.deltas, isEmpty);
    });
  });

  group('export with group sections', () {
    final pt = lookupAppLocalizations(const Locale('pt'));
    final groups = [grp('g1', name: 'Clínica')];
    final data = [
      input(queue('a', groupId: 'g1'), [
        e('1', today, phone: '(11) 99999-1111'),
        e('2', today, phone: '(11) 99999-2222'),
        e('3', lastWeek, phone: '(11) 99999-3333'),
      ]),
      input(queue('b'), [e('4', today, phone: '(11) 99999-4444')]),
    ];

    MetricsReport build({
      List<GroupComparison> groupRows = const [],
      List<QueueComparison> queueRows = const [],
    }) => buildMetricsReport(
      data: data,
      period: HistoryPeriod.last7Days,
      now: now,
      historyLimit: 500,
      unknownOperatorName: 'ex',
      groupRows: groupRows,
      queueRows: queueRows,
    );

    String csv(MetricsReport r) =>
        buildMetricsCsv(pt, r, generatedAt: DateTime(2026, 10, 7));

    test('csv without rows has no group sections', () {
      final text = csv(build());
      expect(text, isNot(contains('Por grupo')));
      expect(text, isNot(contains('Comparativo entre filas do grupo')));
    });

    test('csv lists groups with Sem grupo, stats and variation', () {
      final text = csv(build(groupRows: groupsOf(data, groups)));
      final lines = text.split('\r\n');
      final i = lines.indexOf('Por grupo');
      expect(i, greaterThan(0));
      expect(lines[i + 1], startsWith('grupo,filas,total,'));
      expect(lines[i + 2], startsWith('Clínica,1,2,'));
      expect(lines[i + 2], contains(',+100.0,'));
      expect(lines[i + 3], startsWith('Sem grupo,1,1,'));
      expect(lines[i + 4], '');
    });

    test('csv lists the queue comparison with median and P90 columns', () {
      final rows = compareQueues(
        [data[0]],
        period: HistoryPeriod.last7Days,
        now: now,
      );
      final text = csv(build(queueRows: rows));
      final lines = text.split('\r\n');
      final i = lines.indexOf('Comparativo entre filas do grupo');
      expect(i, greaterThan(0));
      expect(lines[i + 1], contains('mediana (min)'));
      expect(lines[i + 1], contains('P90 (min)'));
      expect(lines[i + 2], startsWith('Fila a,2,'));
    });

    test('partial rows are flagged and have empty variation cells', () {
      final rows = groupsOf(
        [
          input(queue('a', groupId: 'g1'), [
            e('1', today),
            e('2', today),
            e('3', today),
          ]),
        ],
        groups,
        limit: 3,
      );
      final text = csv(build(groupRows: rows));
      expect(text, contains('dados parciais'));
      final line = text
          .split('\r\n')
          .firstWhere((l) => l.startsWith('Clínica,'));
      expect(line, contains(',sim,,,,,'));
    });

    test('csv and pdf never carry phone numbers', () async {
      final report = build(
        groupRows: groupsOf(data, groups),
        queueRows: compareQueues(
          [data[0]],
          period: HistoryPeriod.last7Days,
          now: now,
        ),
      );
      final text = csv(report);
      expect(text, isNot(contains('99999')));
      expect(text, isNot(contains('(11)')));
      final bytes = await buildMetricsPdf(
        l10n: pt,
        report: report,
        generatedAt: DateTime(2026, 10, 7),
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      expect(String.fromCharCodes(bytes), isNot(contains('99999')));
    });

    test('pdf builds in every locale with both sections', () async {
      final report = build(
        groupRows: groupsOf(data, groups),
        queueRows: compareQueues(
          data,
          period: HistoryPeriod.last7Days,
          now: now,
        ),
      );
      for (final l in ['pt', 'en', 'es']) {
        final bytes = await buildMetricsPdf(
          l10n: lookupAppLocalizations(Locale(l)),
          report: report,
          generatedAt: DateTime(2026, 10, 7),
        );
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      }
    });
  });
}
