import '../l10n/app_localizations.dart';
import '../models/history_entry.dart';
import '../models/operator.dart';
import '../models/queue.dart';
import '../models/queue_feedback.dart';
import 'history_export.dart';
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
    required this.historyLimit,
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
  final int historyLimit;

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
    historyLimit: historyLimit,
  );
}

String _num(double? v) => v == null ? '' : v.toStringAsFixed(1);

String _scopeLabel(AppLocalizations l10n, MetricsReport report) =>
    report.operatorQueueName ?? l10n.operatorFilterAll;

String _operatorName(AppLocalizations l10n, MetricsReport report, int i) =>
    report.operatorLabel(
      report.operators[i],
      ownerLabel: l10n.ownerAttendant,
      unknownLabel: l10n.formerOperator,
    );

String buildMetricsCsv(
  AppLocalizations l10n,
  MetricsReport report, {
  required DateTime generatedAt,
}) {
  final m = report.metrics;
  final sections = <List<List<String>>>[
    [
      [l10n.metricsPdfTitle],
      [l10n.csvPeriod, report.period.label(l10n)],
      [l10n.csvScope, _scopeLabel(l10n, report)],
      [l10n.csvGeneratedAt, formatExportDateTime(generatedAt)],
      if (report.truncated) [l10n.historyTruncatedWarning(report.historyLimit)],
    ],
    [
      [l10n.metricsTotal],
      [l10n.csvMetric, l10n.csvValue],
      [l10n.csvTotal, '${m.total}'],
      [l10n.csvServed, '${m.served}'],
      [l10n.csvNoShow, '${m.noShow}'],
      [l10n.csvLeft, '${m.left}'],
      [l10n.csvNoShowRatePct, _num(m.noShowRate * 100)],
      [l10n.csvAvgWaitMin, _num(m.avgWaitMin)],
      [l10n.csvAvgServiceMin, _num(m.avgServiceMin)],
    ],
    [
      [l10n.peakHoursTitle],
      [l10n.csvHour, l10n.csvEntries],
      for (var h = 0; h < report.distribution.length; h++)
        ['$h', '${report.distribution[h]}'],
    ],
    [
      [l10n.mostActiveQueues],
      [
        l10n.csvPosition,
        l10n.csvQueue,
        l10n.csvTotal,
        l10n.csvNoShow,
        l10n.csvNoShowRatePct,
      ],
      for (var i = 0; i < report.ranking.length; i++)
        [
          '${i + 1}',
          report.ranking[i].name,
          '${report.ranking[i].metrics.total}',
          '${report.ranking[i].metrics.noShow}',
          _num(report.ranking[i].metrics.noShowRate * 100),
        ],
    ],
    [
      [l10n.byOperatorTitle],
      if (report.operators.isEmpty)
        [l10n.noOperatorData]
      else ...[
        [
          l10n.csvAttendant,
          l10n.csvServed,
          l10n.csvNoShow,
          l10n.csvAvgServiceMin,
          l10n.csvAvgRating,
          l10n.csvRatingCount,
        ],
        for (var i = 0; i < report.operators.length; i++)
          [
            _operatorName(l10n, report, i),
            '${report.operators[i].served}',
            '${report.operators[i].noShow}',
            _num(report.operators[i].avgServiceMin),
            _num(report.operators[i].feedback.average),
            '${report.operators[i].feedback.count}',
          ],
      ],
    ],
  ];
  final lines = <String>[];
  for (var i = 0; i < sections.length; i++) {
    if (i > 0) lines.add('');
    for (final row in sections[i]) {
      lines.add(row.map(csvCell).join(','));
    }
  }
  return '\u{FEFF}${lines.join('\r\n')}\r\n';
}
