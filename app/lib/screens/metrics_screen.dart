import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/history_entry.dart';
import '../models/operator.dart';
import '../models/queue_group.dart';
import '../models/queue_feedback.dart';
import '../services/history_export.dart';
import '../services/group_service.dart';
import '../services/history_metrics.dart';
import '../services/metrics_export.dart';
import '../services/operator_metrics.dart';
import '../services/operator_service.dart';
import '../services/queue_analytics.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/group_compare_card.dart';
import '../widgets/qio_card.dart';
import '../widgets/qio_empty_state.dart';
import '../widgets/qio_skeleton.dart';
import '../widgets/qio_responsive_body.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  late Future<List<QueueHistoryInput>> _future = _load();
  HistoryPeriod _period = HistoryPeriod.last7Days;
  String? _operatorQueueId;
  List<QueueHistoryInput> _data = const [];
  bool _exporting = false;
  MetricsScope _scope = MetricsScope.all;
  List<QueueGroup> _groups = const [];
  bool _groupsUnavailable = false;

  String _baseName(DateTime now) =>
      'metricas-${switch (_period) {
        HistoryPeriod.today => 'hoje',
        HistoryPeriod.last7Days => '7dias',
        HistoryPeriod.all => 'tudo',
      }}${_scopeSlug()}-${formatExportDateTime(now).substring(0, 10)}';

  String? _scopeName() {
    switch (_scope.kind) {
      case MetricsScopeKind.all:
        return null;
      case MetricsScopeKind.group:
        for (final g in _groups) {
          if (g.id == _scope.id) return g.name;
        }
      case MetricsScopeKind.queue:
        for (final d in _data) {
          if (d.queue.id == _scope.id) return d.queue.name;
        }
    }
    return null;
  }

  String _scopeSlug() {
    final name = _scopeName();
    if (name == null) return '';
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final kind = _scope.kind == MetricsScopeKind.group ? 'grupo' : 'fila';
    return '-$kind${slug.isEmpty ? '' : '-$slug'}';
  }

  String _scopeLabel(AppLocalizations l10n) {
    final name = _scopeName();
    if (name == null) return l10n.metricsScopeAll;
    return _scope.kind == MetricsScopeKind.group
        ? l10n.metricsScopeGroup(name)
        : l10n.metricsScopeQueue(name);
  }

  MetricsReport _report(AppLocalizations l10n, List<QueueHistoryInput> data) =>
      buildMetricsReport(
        data: filterByScope(data, _groups, _scope),
        scopeLabel: _scopeLabel(l10n),
        period: _period,
        now: DateTime.now(),
        historyLimit: QueueService.historyFetchLimit,
        unknownOperatorName: l10n.formerOperator,
        operatorQueueId: _operatorQueueId,
      );

  Future<void> _export(
    Future<void> Function(MetricsReport report) action,
  ) async {
    if (_exporting) return;
    final report = _report(AppLocalizations.of(context), _data);
    if (report.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).nothingToExport)),
      );
      return;
    }
    setState(() => _exporting = true);
    try {
      await action(report);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).exportMetricsError),
          backgroundColor: QioColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportCsv() => _export((report) async {
    final l10n = AppLocalizations.of(context);
    final bytes = Uint8List.fromList(
      utf8.encode(buildMetricsCsv(l10n, report, generatedAt: DateTime.now())),
    );
    final fileName = '${_baseName(DateTime.now())}.csv';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv', name: fileName)],
        fileNameOverrides: [fileName],
      ),
    );
  });

  Future<void> _exportPdf() => _export((report) async {
    final bytes = await buildMetricsPdf(
      l10n: AppLocalizations.of(context),
      report: report,
      generatedAt: DateTime.now(),
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_baseName(DateTime.now())}.pdf',
    );
  });

  Future<List<QueueHistoryInput>> _load() async {
    final queues = await QueueService.instance.watchOwnerQueues().first;
    final result = await Future.wait([
      for (final q in queues)
        Future.wait([
          QueueService.instance.fetchHistory(q.id),
          QueueService.instance
              .fetchFeedback(q.id)
              .catchError((_) => <QueueFeedback>[]),
          OperatorService.instance
              .fetchOperators(q.id)
              .catchError((_) => <QueueOperator>[]),
        ]).then(
          (r) => QueueHistoryInput(
            q,
            r[0] as List<HistoryEntry>,
            r[1] as List<QueueFeedback>,
            r[2] as List<QueueOperator>,
          ),
        ),
    ]);
    if (_operatorQueueId != null &&
        !result.any((d) => d.queue.id == _operatorQueueId)) {
      _operatorQueueId = null;
    }
    var groups = const <QueueGroup>[];
    var groupsUnavailable = false;
    try {
      groups = await GroupService.instance.fetchGroups();
    } on GroupPermissionDeniedException {
      groupsUnavailable = true;
    } on Exception {
      groups = const [];
    }
    _scope = sanitizeScope(_scope, result, groups);
    if (mounted) {
      setState(() {
        _data = result;
        _groups = groups;
        _groupsUnavailable = groupsUnavailable;
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: QioColors.gray100,
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        title: Text(
          l10n.metricsTitle,
          style: QioTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: QioColors.textPrimary,
          ),
        ),
        actions: [
          if (_data.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: l10n.exportTooltip,
              icon: const Icon(Icons.file_download_outlined),
              enabled: !_exporting,
              onSelected: (v) => v == 'csv' ? _exportCsv() : _exportPdf(),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'csv', child: Text(l10n.exportCsv)),
                PopupMenuItem(value: 'pdf', child: Text(l10n.exportPdf)),
              ],
            ),
        ],
      ),
      body: QioResponsiveBody(
        child: FutureBuilder<List<QueueHistoryInput>>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              return QioErrorState(
                message: l10n.loadMetricsError,
                onRetry: () => setState(() {
                  _data = const [];
                  _future = _load();
                }),
              );
            }
            if (!snap.hasData) {
              return const QioSkeletonList(count: 3);
            }
            return _buildContent(l10n, snap.data!);
          },
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, List<QueueHistoryInput> data) {
    if (data.isEmpty) {
      return QioEmptyState(icon: Icons.bar_chart, title: l10n.noQueuesYet);
    }
    final scoped = filterByScope(data, _groups, _scope);
    final report = _report(l10n, data);
    final metrics = report.metrics;
    final distribution = report.distribution;
    final peaks = report.peaks;
    final ranking = report.ranking;
    final pct = (metrics.noShowRate * 100).round();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final p in HistoryPeriod.values)
              ChoiceChip(
                label: Text(p.label(l10n)),
                selected: _period == p,
                onSelected: (_) => setState(() => _period = p),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildScopeSelector(l10n, data),
        if (_groupsUnavailable)
          Text(l10n.groupsUnavailable, style: QioTextStyles.caption),
        const SizedBox(height: 16),
        if (report.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: QioEmptyState(
              icon: Icons.bar_chart,
              title: l10n.noMetricsData,
              message: l10n.emptyMetricsHint,
              compact: true,
            ),
          )
        else ...[
          QioCard(
            child: Column(
              children: [
                Row(
                  children: [
                    _Stat(label: l10n.metricsTotal, value: '${metrics.total}'),
                    _Stat(
                      label: l10n.noShowPlural,
                      value: '${metrics.noShow} ($pct%)',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Stat(
                      label: l10n.avgWait,
                      value: _minutes(l10n, metrics.avgWaitMin),
                    ),
                    _Stat(
                      label: l10n.avgService,
                      value: _minutes(l10n, metrics.avgServiceMin),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          QioCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.peakHoursTitle, style: QioTextStyles.heading3),
                const SizedBox(height: 4),
                Text(l10n.peakHoursSubtitle, style: QioTextStyles.caption),
                const SizedBox(height: 16),
                _HourlyChart(
                  distribution: distribution,
                  summary: peaks.isEmpty
                      ? l10n.noPeakData
                      : l10n.peakHoursTop(
                          peaks
                              .map((h) => '${h.toString().padLeft(2, '0')}h')
                              .join(', '),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  peaks.isEmpty
                      ? l10n.noPeakData
                      : l10n.peakHoursTop(
                          peaks
                              .map((h) => '${h.toString().padLeft(2, '0')}h')
                              .join(', '),
                        ),
                  style: QioTextStyles.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.mostActiveQueues, style: QioTextStyles.heading3),
          const SizedBox(height: 8),
          for (final r in ranking)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: QioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: QioTextStyles.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      l10n.queueActivityLine(
                        r.metrics.total,
                        (r.metrics.noShowRate * 100).round(),
                      ),
                      style: QioTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_scope.kind == MetricsScopeKind.group) ...[
            GroupCompareSection(
              rows: compareQueues(scoped, period: _period, now: DateTime.now()),
            ),
            const SizedBox(height: 16),
          ],
          _buildOperatorSection(l10n, scoped, report),
        ],
      ],
    );
  }

  Widget _buildScopeSelector(
    AppLocalizations l10n,
    List<QueueHistoryInput> data,
  ) {
    return Semantics(
      label: l10n.metricsScopeLabel,
      child: DropdownButton<MetricsScope>(
        isExpanded: true,
        value: _scope,
        onChanged: (v) => setState(() {
          _scope = v ?? MetricsScope.all;
          _operatorQueueId = null;
        }),
        items: [
          DropdownMenuItem(
            value: MetricsScope.all,
            child: Text(l10n.metricsScopeAll),
          ),
          for (final g in _groups)
            DropdownMenuItem(
              value: MetricsScope.group(g.id),
              child: Text(
                l10n.metricsScopeGroup(g.name),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          for (final d in data)
            DropdownMenuItem(
              value: MetricsScope.queue(d.queue.id),
              child: Text(
                l10n.metricsScopeQueue(d.queue.name),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOperatorSection(
    AppLocalizations l10n,
    List<QueueHistoryInput> data,
    MetricsReport report,
  ) {
    final merged = report.operators;
    final truncated = report.truncated;
    final names = report.operatorNames;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.byOperatorTitle, style: QioTextStyles.heading3),
        const SizedBox(height: 8),
        Semantics(
          label: l10n.operatorFilterLabel,
          child: DropdownButton<String?>(
            isExpanded: true,
            value: _operatorQueueId,
            onChanged: (v) => setState(() => _operatorQueueId = v),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.operatorFilterAll),
              ),
              for (final d in data)
                DropdownMenuItem<String?>(
                  value: d.queue.id,
                  child: Text(d.queue.name, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        ),
        if (truncated) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.historyTruncatedWarning(QueueService.historyFetchLimit),
              style: QioTextStyles.caption,
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (merged.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l10n.noOperatorData, style: QioTextStyles.body),
          )
        else
          for (final s in merged)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OperatorRow(
                stats: s,
                name: s.attendantId == null
                    ? l10n.ownerAttendant
                    : names[s.attendantId] ?? l10n.formerOperator,
              ),
            ),
      ],
    );
  }
}

String _minutes(AppLocalizations l10n, double? v) {
  if (v == null) return '—';
  if (v < 1) return l10n.durationLessThanMinute;
  return l10n.durationMinutes(v.round());
}

class _OperatorRow extends StatelessWidget {
  const _OperatorRow({required this.stats, required this.name});

  final OperatorStats stats;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = l10n.operatorCountsLine(stats.served, stats.noShow);
    final rating = stats.feedback.average == null
        ? '—'
        : '${stats.feedback.average!.toStringAsFixed(1)} ★ (${stats.feedback.count})';
    final detail = l10n.operatorDetailLine(
      _minutes(l10n, stats.avgServiceMin),
      rating,
    );
    return Semantics(
      label: '$name. $counts. $detail',
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          child: QioCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: QioTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(counts, style: QioTextStyles.caption),
                Text(detail, style: QioTextStyles.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: QioTextStyles.label),
          const SizedBox(height: 4),
          Text(value, style: QioTextStyles.heading2),
        ],
      ),
    );
  }
}

class _HourlyChart extends StatelessWidget {
  const _HourlyChart({required this.distribution, required this.summary});

  final List<int> distribution;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final max = distribution.fold<int>(0, (m, v) => v > m ? v : m);
    return Semantics(
      label: summary,
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var h = 0; h < 24; h++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Container(
                          height: max == 0 ? 2 : 2 + 98 * distribution[h] / max,
                          decoration: BoxDecoration(
                            color: distribution[h] == 0
                                ? QioColors.gray200
                                : QioColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final h in const [0, 6, 12, 18, 23])
                  Text('${h}h', style: QioTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
