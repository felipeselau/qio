import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/history_entry.dart';
import '../models/queue_feedback.dart';
import '../services/history_export.dart';
import '../services/history_metrics.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.queueId, this.queueName = ''});

  final String queueId;
  final String queueName;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Stream<List<HistoryEntry>> _stream;
  HistoryPeriod _period = HistoryPeriod.all;
  String? _result;
  List<HistoryEntry> _filtered = const [];
  bool _exporting = false;
  StreamSubscription<List<QueueFeedback>>? _feedbackSub;
  Map<String, QueueFeedback> _feedback = const {};

  String get _baseName => 'historico-${widget.queueId}';

  Future<void> _export(Future<void> Function() action) async {
    if (_exporting) return;
    if (_filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).nothingToExport)),
      );
      return;
    }
    setState(() => _exporting = true);
    try {
      await action();
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).exportError),
          backgroundColor: QioColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportCsv() => _export(() async {
    final l10n = AppLocalizations.of(context);
    final bytes = Uint8List.fromList(
      utf8.encode(buildHistoryCsv(l10n, _filtered)),
    );
    final fileName = '$_baseName.csv';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv', name: fileName)],
        fileNameOverrides: [fileName],
      ),
    );
  });

  Future<void> _exportPdf() => _export(() async {
    final bytes = await buildHistoryPdf(
      l10n: AppLocalizations.of(context),
      queueName: widget.queueName,
      entries: _filtered,
      generatedAt: DateTime.now(),
    );
    await Printing.sharePdf(bytes: bytes, filename: '$_baseName.pdf');
  });

  @override
  void initState() {
    super.initState();
    _stream = QueueService.instance.watchHistory(widget.queueId);
    _feedbackSub = QueueService.instance.watchFeedback(widget.queueId).listen((
      list,
    ) {
      if (!mounted) return;
      setState(() => _feedback = {for (final f in list) f.entryId: f});
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _feedbackSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: QioColors.gray100,
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        title: Text(
          l10n.historyTitle,
          style: QioTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: QioColors.textPrimary,
          ),
        ),
        actions: [
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
      body: StreamBuilder<List<HistoryEntry>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.loadHistoryError,
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
                l10n.noHistoryYet,
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
          _filtered = filtered;
          final metrics = computeHistoryMetrics(filtered);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildFilters(),
              const SizedBox(height: 16),
              _MetricsCard(
                metrics: metrics,
                feedback: summarizeFeedback(
                  _feedback.values,
                  onlyEntryIds: {for (final e in filtered) e.id},
                ),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      l10n.noHistoryInFilter,
                      style: QioTextStyles.caption,
                    ),
                  ),
                )
              else
                for (final e in filtered)
                  _HistoryTile(entry: e, rating: _feedback[e.id]?.rating),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    final l10n = AppLocalizations.of(context);
    final resultOptions = <String, String?>{
      l10n.filterAll: null,
      l10n.servedPlural: 'served',
      l10n.noShowPlural: 'no_show',
      l10n.leftPlural: 'left',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Wrap(
          spacing: 8,
          children: [
            for (final o in resultOptions.entries)
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

String _formatMinutes(AppLocalizations l10n, double? v) {
  if (v == null) return '—';
  if (v < 1) return l10n.durationLessThanMinute;
  return l10n.durationMinutes(v.round());
}

String _formatDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.metrics, required this.feedback});

  final HistoryMetrics metrics;
  final FeedbackSummary feedback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pct = (metrics.noShowRate * 100).round();
    return QioCard(
      child: Column(
        children: [
          Row(
            children: [
              _Metric(label: l10n.servedPlural, value: '${metrics.served}'),
              _Metric(
                label: l10n.noShowPlural,
                value: '${metrics.noShow} ($pct%)',
              ),
              _Metric(label: l10n.leftPlural, value: '${metrics.left}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(
                label: l10n.avgWait,
                value: _formatMinutes(l10n, metrics.avgWaitMin),
              ),
              _Metric(
                label: l10n.avgService,
                value: _formatMinutes(l10n, metrics.avgServiceMin),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(
                label: l10n.avgRating,
                value: feedback.average == null
                    ? '—'
                    : '${feedback.average!.toStringAsFixed(1)} ★ (${feedback.count})',
              ),
              const Expanded(child: SizedBox.shrink()),
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
  const _HistoryTile({required this.entry, this.rating});

  final HistoryEntry entry;
  final int? rating;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = entry.isServed
        ? QioColors.success
        : entry.isLeft
        ? QioColors.textSecondary
        : QioColors.error;
    final label = entry.isServed
        ? l10n.served
        : entry.isLeft
        ? l10n.resultLeft
        : l10n.noShow;
    final wait = entry.wait;
    final subtitle = [
      _formatDateTime(entry.referenceTime),
      if (wait != null)
        l10n.waitSubtitle(_formatMinutes(l10n, wait.inMilliseconds / 60000)),
      if (rating != null) '★ $rating',
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
                    l10n.ticketAndName(entry.ticket, entry.name),
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
