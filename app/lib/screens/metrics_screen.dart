import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/history_entry.dart';
import '../models/operator.dart';
import '../models/queue.dart';
import '../models/queue_feedback.dart';
import '../services/history_metrics.dart';
import '../services/operator_metrics.dart';
import '../services/operator_service.dart';
import '../services/queue_analytics.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_card.dart';
import '../widgets/qio_empty_state.dart';
import '../widgets/qio_skeleton.dart';
import '../widgets/qio_responsive_body.dart';

class _QueueHistory {
  const _QueueHistory(this.queue, this.entries, this.feedback, this.operators);

  final Queue queue;
  final List<HistoryEntry> entries;
  final List<QueueFeedback> feedback;
  final List<QueueOperator> operators;
}

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  late Future<List<_QueueHistory>> _future = _load();
  HistoryPeriod _period = HistoryPeriod.last7Days;
  String? _operatorQueueId;

  Future<List<_QueueHistory>> _load() async {
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
          (r) => _QueueHistory(
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
      ),
      body: QioResponsiveBody(
        child: FutureBuilder<List<_QueueHistory>>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              return QioErrorState(
                message: l10n.loadMetricsError,
                onRetry: () => setState(() => _future = _load()),
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

  Widget _buildContent(AppLocalizations l10n, List<_QueueHistory> data) {
    if (data.isEmpty) {
      return QioEmptyState(icon: Icons.bar_chart, title: l10n.noQueuesYet);
    }
    final now = DateTime.now();
    final perQueue = [
      for (final d in data)
        (
          queue: d.queue,
          entries: filterHistory(d.entries, period: _period, now: now),
        ),
    ];
    final all = [for (final p in perQueue) ...p.entries];
    final metrics = computeHistoryMetrics(all);
    final distribution = hourlyDistribution(all);
    final peaks = peakHours(distribution);
    final ranking = rankByActivity([
      for (final p in perQueue)
        QueueActivity(
          queueId: p.queue.id,
          name: p.queue.name,
          metrics: computeHistoryMetrics(p.entries),
        ),
    ]);
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
        const SizedBox(height: 16),
        if (all.isEmpty)
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
          _buildOperatorSection(l10n, data, now),
        ],
      ],
    );
  }

  Widget _buildOperatorSection(
    AppLocalizations l10n,
    List<_QueueHistory> data,
    DateTime now,
  ) {
    final selected = data
        .where(
          (d) => _operatorQueueId == null || d.queue.id == _operatorQueueId,
        )
        .toList();
    final truncated = selected.any((d) {
      if (d.entries.length < QueueService.historyFetchLimit) return false;
      final oldest = d.entries.reduce(
        (a, b) => a.referenceTime.isBefore(b.referenceTime) ? a : b,
      );
      return filterHistory([oldest], period: _period, now: now).isNotEmpty;
    });
    final names = <String, String>{
      for (final d in data)
        for (final o in d.operators) o.uid: o.label,
    };
    final merged = computeOperatorMetrics(
      [
        for (final d in selected)
          ...filterHistory(d.entries, period: _period, now: now),
      ],
      ownerUids: {for (final d in selected) d.queue.ownerId},
      feedback: [for (final d in selected) ...d.feedback],
      names: names,
      unknownName: l10n.formerOperator,
    );
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
