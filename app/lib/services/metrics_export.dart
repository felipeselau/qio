import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

String _minutesLabel(AppLocalizations l10n, double? v) {
  if (v == null) return '-';
  if (v < 1) return l10n.durationLessThanMinute;
  return l10n.durationMinutes(v.round());
}

String _ratingLabel(OperatorStats s) => s.feedback.average == null
    ? '-'
    : '${s.feedback.average!.toStringAsFixed(1)} (${s.feedback.count})';

String _hourLabel(int h) => '${h.toString().padLeft(2, '0')}h';

pw.Widget _section(String title) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
  child: pw.Text(
    title,
    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
  ),
);

pw.Widget _table(List<String> headers, List<List<String>> data) =>
    pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    );

pw.Widget _metric(String label, String value) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Text(
      label,
      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
    ),
    pw.Text(
      value,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    ),
  ],
);

Future<Uint8List> buildMetricsPdf({
  required AppLocalizations l10n,
  required MetricsReport report,
  required DateTime generatedAt,
}) {
  final m = report.metrics;
  final pct = (m.noShowRate * 100).round();
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l10n.metricsPdfTitle,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${l10n.csvPeriod}: ${report.period.label(l10n)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            '${l10n.csvScope}: ${_scopeLabel(l10n, report)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            l10n.pdfGeneratedAt(formatExportDateTime(generatedAt)),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
        ],
      ),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${ctx.pageNumber}/${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ),
      build: (_) => [
        if (report.truncated)
          pw.Text(
            l10n.historyTruncatedWarning(report.historyLimit),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        if (report.isEmpty)
          pw.Text(l10n.pdfNoRecords)
        else ...[
          _section(l10n.metricsTotal),
          pw.Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _metric(l10n.pdfTotal, '${m.total}'),
              _metric(l10n.servedPlural, '${m.served}'),
              _metric(l10n.noShowPlural, '${m.noShow} ($pct%)'),
              _metric(l10n.leftPlural, '${m.left}'),
              _metric(l10n.avgWait, _minutesLabel(l10n, m.avgWaitMin)),
              _metric(l10n.avgService, _minutesLabel(l10n, m.avgServiceMin)),
            ],
          ),
          _section(l10n.peakHoursTitle),
          pw.Text(
            report.peaks.isEmpty
                ? l10n.noPeakData
                : l10n.peakHoursTop(report.peaks.map(_hourLabel).join(', ')),
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 6),
          _table(
            [l10n.csvHour, l10n.csvEntries],
            [
              for (var h = 0; h < report.distribution.length; h++)
                if (report.distribution[h] > 0)
                  [_hourLabel(h), '${report.distribution[h]}'],
            ],
          ),
          _section(l10n.mostActiveQueues),
          _table(
            [
              l10n.csvPosition,
              l10n.csvQueue,
              l10n.csvTotal,
              l10n.csvNoShow,
              l10n.csvNoShowRatePct,
            ],
            [
              for (var i = 0; i < report.ranking.length; i++)
                [
                  '${i + 1}',
                  report.ranking[i].name,
                  '${report.ranking[i].metrics.total}',
                  '${report.ranking[i].metrics.noShow}',
                  '${(report.ranking[i].metrics.noShowRate * 100).round()}',
                ],
            ],
          ),
          _section(l10n.byOperatorTitle),
          if (report.operators.isEmpty)
            pw.Text(l10n.noOperatorData)
          else
            _table(
              [
                l10n.csvAttendant,
                l10n.csvServed,
                l10n.csvNoShow,
                l10n.csvAvgServiceMin,
                l10n.csvAvgRating,
              ],
              [
                for (var i = 0; i < report.operators.length; i++)
                  [
                    _operatorName(l10n, report, i),
                    '${report.operators[i].served}',
                    '${report.operators[i].noShow}',
                    _minutesLabel(l10n, report.operators[i].avgServiceMin),
                    _ratingLabel(report.operators[i]),
                  ],
              ],
            ),
        ],
      ],
    ),
  );
  return doc.save();
}
