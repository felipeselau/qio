import '../models/history_entry.dart';
import '../models/queue_feedback.dart';
import '../models/queue_group.dart';
import '../models/queue_history_input.dart';
import 'history_metrics.dart';
import 'metrics_trend.dart';

List<int> hourlyDistribution(List<HistoryEntry> entries) {
  final counts = List<int>.filled(24, 0);
  for (final e in entries) {
    counts[e.joinedAt.hour]++;
  }
  return counts;
}

List<int> peakHours(List<int> distribution, {int top = 3}) {
  final hours = [
    for (var h = 0; h < distribution.length; h++)
      if (distribution[h] > 0) h,
  ];
  hours.sort((a, b) {
    final byCount = distribution[b].compareTo(distribution[a]);
    return byCount != 0 ? byCount : a.compareTo(b);
  });
  return hours.take(top).toList();
}

class QueueActivity {
  const QueueActivity({
    required this.queueId,
    required this.name,
    required this.metrics,
  });

  final String queueId;
  final String name;
  final HistoryMetrics metrics;
}

List<QueueActivity> rankByActivity(List<QueueActivity> items) {
  final sorted = [...items]
    ..sort((a, b) {
      final byTotal = b.metrics.total.compareTo(a.metrics.total);
      return byTotal != 0 ? byTotal : a.name.compareTo(b.name);
    });
  return sorted;
}

enum MetricsScopeKind { all, group, ungrouped, queue }

class MetricsScope {
  const MetricsScope._(this.kind, this.id);

  static const all = MetricsScope._(MetricsScopeKind.all, null);
  static const ungrouped = MetricsScope._(MetricsScopeKind.ungrouped, null);
  const MetricsScope.group(String id) : this._(MetricsScopeKind.group, id);
  const MetricsScope.queue(String id) : this._(MetricsScopeKind.queue, id);

  final MetricsScopeKind kind;
  final String? id;

  @override
  bool operator ==(Object other) =>
      other is MetricsScope && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

List<QueueHistoryInput> filterByScope(
  List<QueueHistoryInput> data,
  List<QueueGroup> groups,
  MetricsScope scope,
) {
  switch (scope.kind) {
    case MetricsScopeKind.all:
      return data;
    case MetricsScopeKind.group:
      return [
        for (final d in data)
          if (resolveGroupId(d.queue, groups) == scope.id) d,
      ];
    case MetricsScopeKind.ungrouped:
      return [
        for (final d in data)
          if (resolveGroupId(d.queue, groups) == null) d,
      ];
    case MetricsScopeKind.queue:
      return [
        for (final d in data)
          if (d.queue.id == scope.id) d,
      ];
  }
}

MetricsScope sanitizeScope(
  MetricsScope scope,
  List<QueueHistoryInput> data,
  List<QueueGroup> groups,
) {
  switch (scope.kind) {
    case MetricsScopeKind.all:
      return scope;
    case MetricsScopeKind.group:
      return groups.any((g) => g.id == scope.id) ? scope : MetricsScope.all;
    case MetricsScopeKind.ungrouped:
      return data.any((d) => resolveGroupId(d.queue, groups) == null)
          ? scope
          : MetricsScope.all;
    case MetricsScopeKind.queue:
      return data.any((d) => d.queue.id == scope.id) ? scope : MetricsScope.all;
  }
}

const defaultHistoryLimit = 500;

class ComparisonStats {
  const ComparisonStats({
    required this.metrics,
    required this.feedback,
    this.waitStats = const WaitStats(samples: 0, bucketCounts: [0, 0, 0, 0]),
    this.deltas = const {},
    this.partial = false,
  });

  final HistoryMetrics metrics;
  final FeedbackSummary feedback;
  final WaitStats waitStats;
  final Map<MetricKey, Delta> deltas;
  final bool partial;
}

class QueueComparison extends ComparisonStats {
  const QueueComparison({
    required this.queueId,
    required this.name,
    required super.metrics,
    required super.feedback,
    super.waitStats,
    super.deltas,
    super.partial,
  });

  final String queueId;
  final String name;
}

class GroupComparison extends ComparisonStats {
  const GroupComparison({
    required this.groupId,
    required this.name,
    required this.queueCount,
    required super.metrics,
    required super.feedback,
    super.waitStats,
    super.deltas,
    super.partial,
  });

  final String? groupId;
  final String name;
  final int queueCount;
}

ComparisonStats _comparisonStats(
  List<QueueHistoryInput> items, {
  required HistoryPeriod period,
  required DateTime now,
  required int historyLimit,
  DateRange? custom,
}) {
  final perQueue = [
    for (final d in items)
      filterHistory(d.entries, period: period, now: now, custom: custom),
  ];
  final entries = [for (final e in perQueue) ...e];
  final metrics = computeHistoryMetrics(entries);
  final waitStats = computeWaitStats(entries);
  final feedback = summarizeFeedback(
    [for (final d in items) ...d.feedback],
    onlyEntryIds: {
      for (final e in entries)
        if (e.isServed) e.id,
    },
  );
  final truncated = items.any((d) {
    if (d.entries.length < historyLimit) return false;
    final oldest = d.entries.reduce(
      (a, b) => a.referenceTime.isBefore(b.referenceTime) ? a : b,
    );
    return filterHistory(
      [oldest],
      period: period,
      now: now,
      custom: custom,
    ).isNotEmpty;
  });
  var deltas = const <MetricKey, Delta>{};
  final range = rangeFor(period, now, custom: custom);
  if (range != null && !truncated) {
    final prev = range.previous();
    final window = range.previousAligned(now);
    final incomplete = items.any(
      (d) =>
          d.entries.length >= historyLimit &&
          d.entries.every((e) => !e.referenceTime.isBefore(prev.start)),
    );
    if (!incomplete) {
      final prevEntries = [
        for (final d in items)
          ...d.entries.where((e) => window.contains(e.referenceTime)),
      ];
      deltas = compare(
        metrics,
        computeHistoryMetrics(prevEntries),
        curWait: waitStats,
        prevWait: computeWaitStats(prevEntries),
      );
    }
  }
  return ComparisonStats(
    metrics: metrics,
    feedback: feedback,
    waitStats: waitStats,
    deltas: deltas,
    partial: truncated,
  );
}

List<QueueComparison> compareQueues(
  List<QueueHistoryInput> data, {
  required HistoryPeriod period,
  required DateTime now,
  DateRange? custom,
  int historyLimit = defaultHistoryLimit,
}) {
  final items = <QueueComparison>[];
  for (final d in data) {
    final s = _comparisonStats(
      [d],
      period: period,
      now: now,
      custom: custom,
      historyLimit: historyLimit,
    );
    items.add(
      QueueComparison(
        queueId: d.queue.id,
        name: d.queue.name,
        metrics: s.metrics,
        feedback: s.feedback,
        waitStats: s.waitStats,
        deltas: s.deltas,
        partial: s.partial,
      ),
    );
  }
  items.sort((a, b) {
    final byTotal = b.metrics.total.compareTo(a.metrics.total);
    return byTotal != 0 ? byTotal : a.name.compareTo(b.name);
  });
  return items;
}

List<GroupComparison> compareGroups(
  List<QueueHistoryInput> data,
  List<QueueGroup> groups, {
  required HistoryPeriod period,
  required DateTime now,
  DateRange? custom,
  int historyLimit = defaultHistoryLimit,
}) {
  final buckets = <String?, List<QueueHistoryInput>>{};
  for (final d in data) {
    buckets.putIfAbsent(resolveGroupId(d.queue, groups), () => []).add(d);
  }
  final rows = <GroupComparison>[];
  for (final entry in buckets.entries) {
    final id = entry.key;
    final s = _comparisonStats(
      entry.value,
      period: period,
      now: now,
      custom: custom,
      historyLimit: historyLimit,
    );
    rows.add(
      GroupComparison(
        groupId: id,
        name: id == null ? '' : groups.firstWhere((g) => g.id == id).name,
        queueCount: entry.value.length,
        metrics: s.metrics,
        feedback: s.feedback,
        waitStats: s.waitStats,
        deltas: s.deltas,
        partial: s.partial,
      ),
    );
  }
  rows.sort((a, b) {
    final byTotal = b.metrics.total.compareTo(a.metrics.total);
    if (byTotal != 0) return byTotal;
    if ((a.groupId == null) != (b.groupId == null)) {
      return a.groupId == null ? 1 : -1;
    }
    return a.name.compareTo(b.name);
  });
  return rows;
}

List<int> weekdayDistribution(List<HistoryEntry> entries) {
  final counts = List<int>.filled(7, 0);
  for (final e in entries) {
    counts[e.joinedAt.weekday - 1]++;
  }
  return counts;
}

List<List<int>> weekdayHourMatrix(List<HistoryEntry> entries) {
  final matrix = [for (var d = 0; d < 7; d++) List<int>.filled(24, 0)];
  for (final e in entries) {
    matrix[e.joinedAt.weekday - 1][e.joinedAt.hour]++;
  }
  return matrix;
}

class DemandPeak {
  const DemandPeak({
    required this.weekday,
    required this.hour,
    required this.count,
  });

  final int weekday;
  final int hour;
  final int count;
}

DemandPeak? peakCell(List<List<int>> matrix) {
  DemandPeak? best;
  for (var d = 0; d < matrix.length; d++) {
    for (var h = 0; h < matrix[d].length; h++) {
      final c = matrix[d][h];
      if (c > 0 && (best == null || c > best.count)) {
        best = DemandPeak(weekday: d, hour: h, count: c);
      }
    }
  }
  return best;
}
