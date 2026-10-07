import '../models/history_entry.dart';
import '../models/operator.dart';
import '../models/queue.dart';
import '../models/queue_feedback.dart';
import 'history_metrics.dart';
import 'operator_metrics.dart';
import 'queue_analytics.dart';

class QueueHistoryInput {
  const QueueHistoryInput(
    this.queue,
    this.entries,
    this.feedback,
    this.operators,
  );

  final Queue queue;
  final List<HistoryEntry> entries;
  final List<QueueFeedback> feedback;
  final List<QueueOperator> operators;
}

class MetricsReport {
  const MetricsReport({
    required this.period,
    required this.operatorQueueId,
    required this.operatorQueueName,
    required this.isEmpty,
    required this.metrics,
    required this.distribution,
    required this.peaks,
    required this.ranking,
    required this.operators,
    required this.operatorNames,
    required this.truncated,
  });

  final HistoryPeriod period;
  final String? operatorQueueId;
  final String? operatorQueueName;
  final bool isEmpty;
  final HistoryMetrics metrics;
  final List<int> distribution;
  final List<int> peaks;
  final List<QueueActivity> ranking;
  final List<OperatorStats> operators;
  final Map<String, String> operatorNames;
  final bool truncated;

  String operatorLabel(
    OperatorStats stats, {
    required String ownerLabel,
    required String unknownLabel,
  }) => stats.attendantId == null
      ? ownerLabel
      : operatorNames[stats.attendantId] ?? unknownLabel;
}

MetricsReport buildMetricsReport({
  required List<QueueHistoryInput> data,
  required HistoryPeriod period,
  required DateTime now,
  required int historyLimit,
  required String unknownOperatorName,
  String? operatorQueueId,
}) {
  final perQueue = [
    for (final d in data)
      (
        queue: d.queue,
        entries: filterHistory(d.entries, period: period, now: now),
      ),
  ];
  final all = [for (final p in perQueue) ...p.entries];
  final distribution = hourlyDistribution(all);
  final selected = data
      .where((d) => operatorQueueId == null || d.queue.id == operatorQueueId)
      .toList();
  final truncated = selected.any((d) {
    if (d.entries.length < historyLimit) return false;
    final oldest = d.entries.reduce(
      (a, b) => a.referenceTime.isBefore(b.referenceTime) ? a : b,
    );
    return filterHistory([oldest], period: period, now: now).isNotEmpty;
  });
  final names = <String, String>{
    for (final d in data)
      for (final o in d.operators) o.uid: o.label,
  };
  final operators = computeOperatorMetrics(
    [
      for (final d in selected)
        ...filterHistory(d.entries, period: period, now: now),
    ],
    ownerUids: {for (final d in selected) d.queue.ownerId},
    feedback: [for (final d in selected) ...d.feedback],
    names: names,
    unknownName: unknownOperatorName,
  );
  String? queueName;
  for (final d in data) {
    if (d.queue.id == operatorQueueId) queueName = d.queue.name;
  }
  return MetricsReport(
    period: period,
    operatorQueueId: operatorQueueId,
    operatorQueueName: queueName,
    isEmpty: all.isEmpty,
    metrics: computeHistoryMetrics(all),
    distribution: distribution,
    peaks: peakHours(distribution),
    ranking: rankByActivity([
      for (final p in perQueue)
        QueueActivity(
          queueId: p.queue.id,
          name: p.queue.name,
          metrics: computeHistoryMetrics(p.entries),
        ),
    ]),
    operators: operators,
    operatorNames: names,
    truncated: truncated,
  );
}
