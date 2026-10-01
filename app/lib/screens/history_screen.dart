import 'package:flutter/material.dart';

import '../models/history_entry.dart';
import '../services/history_metrics.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.queueId});

  final String queueId;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _resultOptions = <String, String?>{
    'Todos': null,
    'Atendidos': 'served',
    'Não compareceram': 'no_show',
  };

  late final Stream<List<HistoryEntry>> _stream;
  HistoryPeriod _period = HistoryPeriod.all;
  String? _result;

  @override
  void initState() {
    super.initState();
    _stream = QueueService.instance.watchHistory(widget.queueId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QioColors.gray100,
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        title: Text(
          'Histórico',
          style: QioTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: QioColors.textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<List<HistoryEntry>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar o histórico. Tente novamente.',
                  textAlign: TextAlign.center,
                  style: QioTextStyles.body.copyWith(color: QioColors.error),
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          if (all.isEmpty) {
            return Center(
              child: Text(
                'Nenhum atendimento ainda',
                style: QioTextStyles.body.copyWith(
                  color: QioColors.textSecondary,
                ),
              ),
            );
          }
          final filtered = filterHistory(
            all,
            result: _result,
            period: _period,
            now: DateTime.now(),
          );
          final metrics = computeHistoryMetrics(filtered);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildFilters(),
              const SizedBox(height: 16),
              _MetricsCard(metrics: metrics),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Nenhum atendimento neste filtro',
                      style: QioTextStyles.caption,
                    ),
                  ),
                )
              else
                for (final e in filtered) _HistoryTile(entry: e),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final p in HistoryPeriod.values)
              ChoiceChip(
                label: Text(p.label),
                selected: _period == p,
                onSelected: (_) => setState(() => _period = p),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final o in _resultOptions.entries)
              ChoiceChip(
                label: Text(o.key),
                selected: _result == o.value,
                onSelected: (_) => setState(() => _result = o.value),
              ),
          ],
        ),
      ],
    );
  }
}

String _formatMinutes(double? v) {
  if (v == null) return '—';
  if (v < 1) return '<1 min';
  return '${v.round()} min';
}

String _formatDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.metrics});

  final HistoryMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final pct = (metrics.noShowRate * 100).round();
    return QioCard(
      child: Column(
        children: [
          Row(
            children: [
              _Metric(label: 'Atendidos', value: '${metrics.served}'),
              _Metric(
                label: 'Não compareceram',
                value: '${metrics.noShow} ($pct%)',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(
                label: 'Espera média',
                value: _formatMinutes(metrics.avgWaitMin),
              ),
              _Metric(
                label: 'Atendimento médio',
                value: _formatMinutes(metrics.avgServiceMin),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.isServed ? QioColors.success : QioColors.error;
    final label = entry.isServed ? 'Atendido' : 'Não compareceu';
    final wait = entry.wait;
    final subtitle = [
      _formatDateTime(entry.referenceTime),
      if (wait != null) 'espera ${_formatMinutes(wait.inMilliseconds / 60000)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: QioCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${entry.ticket} ${entry.name}',
                    style: QioTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: QioTextStyles.caption),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: QioTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
