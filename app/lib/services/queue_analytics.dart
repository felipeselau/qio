import '../models/history_entry.dart';
import '../models/queue_feedback.dart';
import '../models/queue_group.dart';
import 'history_metrics.dart';
import 'metrics_export.dart';

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

enum MetricsScopeKind { all, group, queue }

class MetricsScope {
  const MetricsScope._(this.kind, this.id);

  static const all = MetricsScope._(MetricsScopeKind.all, null);
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
    case MetricsScopeKind.queue:
      return [
        for (final d in data)
          if (d.queue.id == scope.id) d,
      ];
  }
}

class QueueComparison {
  const QueueComparison({
    required this.queueId,
    required this.name,
    required this.metrics,
    required this.feedback,
  });

  final String queueId;
  final String name;
  final HistoryMetrics metrics;
  final FeedbackSummary feedback;
}

List<QueueComparison> compareQueues(
  List<QueueHistoryInput> data, {
  required HistoryPeriod period,
  required DateTime now,
}) {
  final items = <QueueComparison>[];
  for (final d in data) {
    final entries = filterHistory(d.entries, period: period, now: now);
    items.add(
      QueueComparison(
        queueId: d.queue.id,
        name: d.queue.name,
        metrics: computeHistoryMetrics(entries),
        feedback: summarizeFeedback(
          d.feedback,
          onlyEntryIds: {
            for (final e in entries)
              if (e.isServed) e.id,
          },
        ),
      ),
    );
  }
  items.sort((a, b) {
    final byTotal = b.metrics.total.compareTo(a.metrics.total);
    return byTotal != 0 ? byTotal : a.name.compareTo(b.name);
  });
  return items;
}
