import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/history_entry.dart';
import '../models/queue.dart';
import '../services/history_metrics.dart';
import '../services/queue_analytics.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_card.dart';

class _QueueHistory {
  const _QueueHistory(this.queue, this.entries);

  final Queue queue;
  final List<HistoryEntry> entries;
}

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  late Future<List<_QueueHistory>> _future = _load();
  HistoryPeriod _period = HistoryPeriod.last7Days;

  Future<List<_QueueHistory>> _load() async {
    final queues = await QueueService.instance.watchOwnerQueues().first;
    return Future.wait([
      for (final q in queues)
        QueueService.instance
            .fetchHistory(q.id)
            .then((entries) => _QueueHistory(q, entries)),
    ]);
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
      body: FutureBuilder<List<_QueueHistory>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.loadMetricsError,
                      textAlign: TextAlign.center,
                      style: QioTextStyles.body.copyWith(
                        color: QioColors.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildContent(l10n, snap.data!);
        },
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, List<_QueueHistory> data) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          l10n.noQueuesYet,
          style: QioTextStyles.body.copyWith(color: QioColors.textSecondary),
        ),
      );
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
            child: Center(
              child: Text(l10n.noMetricsData, style: QioTextStyles.caption),
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
                _HourlyChart(distribution: distribution),
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
        ],
      ],
    );
  }
}

String _minutes(AppLocalizations l10n, double? v) {
  if (v == null) return '—';
  if (v < 1) return l10n.durationLessThanMinute;
  return l10n.durationMinutes(v.round());
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
  const _HourlyChart({required this.distribution});

  final List<int> distribution;

  @override
  Widget build(BuildContext context) {
    final max = distribution.fold<int>(0, (m, v) => v > m ? v : m);
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var h = 0; h < 24; h++)
                Expanded(
                  child: Semantics(
                    label:
                        '${h.toString().padLeft(2, '0')}h: ${distribution[h]}',
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
    );
  }
}
