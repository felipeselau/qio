import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/history_entry.dart';
import '../models/queue.dart';
import '../models/queue_feedback.dart';
import '../services/history_export.dart';
import '../services/group_history.dart';
import '../services/history_metrics.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_card.dart';
import '../widgets/qio_empty_state.dart';
import '../widgets/qio_skeleton.dart';
import '../widgets/qio_responsive_body.dart';
import '../theme/qio_palette.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required String this.queueId,
    this.queueName = '',
    this.queues,
    this.clock,
  }) : groupName = null,
       groupQueues = const [];

  const HistoryScreen.group({
    super.key,
    required String this.groupName,
    required this.groupQueues,
    this.queues,
    this.clock,
  }) : queueId = null,
       queueName = '';

  final String? queueId;
  final String queueName;
  final String? groupName;
  final List<Queue> groupQueues;
  final QueueService? queues;
  @visibleForTesting
  final DateTime Function()? clock;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryData {
  const _HistoryData(this.entries, this.queueNames, this.feedback, this.group);

  final List<HistoryEntry> entries;
  final Map<HistoryEntry, String> queueNames;
  final List<QueueFeedback> feedback;
  final GroupHistory? group;
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Stream<_HistoryData> _stream;
  int _page = 0;
  List<String> _filteredQueues = const [];
  HistoryPeriod _period = HistoryPeriod.all;
  String? _result;
  List<HistoryEntry> _filtered = const [];
  bool _exporting = false;
  StreamSubscription<List<QueueFeedback>>? _feedbackSub;
  Map<String, QueueFeedback> _feedback = const {};

  QueueService get _queues => widget.queues ?? QueueService.instance;

  bool get _isGroup => widget.groupName != null;

  String get _baseName {
    if (!_isGroup) return 'historico-${widget.queueId}';
    final slug = widget.groupName!
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'historico-grupo${slug.isEmpty ? '' : '-$slug'}';
  }

  Stream<_HistoryData> _open() {
    if (!_isGroup) {
      return _queues
          .watchHistory(widget.queueId!)
          .map((e) => _HistoryData(e, const {}, const [], null));
    }
    return Stream.fromFuture(_loadGroup());
  }

  Future<_HistoryData> _loadGroup() async {
    final slices = await Future.wait([
      for (final q in widget.groupQueues)
        Future.wait([
          _queues.fetchHistory(q.id),
          _queues.fetchFeedback(q.id).catchError((_) => <QueueFeedback>[]),
        ]).then(
          (r) => GroupHistorySlice(
            queueId: q.id,
            queueName: q.name,
            entries: r[0] as List<HistoryEntry>,
            feedback: r[1] as List<QueueFeedback>,
          ),
        ),
    ]);
    final group = mergeGroupHistory(slices);
    final names = Map<HistoryEntry, String>.identity();
    for (final i in group.items) {
      names[i.entry] = i.queueName;
    }
    return _HistoryData(
      [for (final i in group.items) i.entry],
      names,
      group.feedback,
      group,
    );
  }

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

  Future<void> _exportCsv({bool includePhone = false}) => _export(() async {
    final l10n = AppLocalizations.of(context);
    final bytes = Uint8List.fromList(
      utf8.encode(
        buildHistoryCsv(
          l10n,
          _filtered,
          includePhone: includePhone,
          queueNames: _isGroup ? _filteredQueues : null,
        ),
      ),
    );
    final fileName = '$_baseName.csv';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv', name: fileName)],
        fileNameOverrides: [fileName],
      ),
    );
  });

  Future<void> _exportPdf({bool includePhone = false}) => _export(() async {
    final bytes = await buildHistoryPdf(
      l10n: AppLocalizations.of(context),
      queueName: _isGroup
          ? AppLocalizations.of(context).metricsScopeGroup(widget.groupName!)
          : widget.queueName,
      entries: _filtered,
      generatedAt: DateTime.now(),
      includePhone: includePhone,
      queueNames: _isGroup ? _filteredQueues : null,
    );
    await Printing.sharePdf(bytes: bytes, filename: '$_baseName.pdf');
  });

  Future<void> _onExportSelected(String value) async {
    switch (value) {
      case 'csv':
        await _exportCsv();
      case 'pdf':
        await _exportPdf();
      case 'csv_phone':
      case 'pdf_phone':
        if (!await _confirmPhoneExport() || !mounted) return;
        if (value == 'csv_phone') {
          await _exportCsv(includePhone: true);
        } else {
          await _exportPdf(includePhone: true);
        }
    }
  }

  Future<bool> _confirmPhoneExport() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exportPhoneTitle),
        content: Text(l10n.exportPhoneWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.exportPhoneConfirm),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  void initState() {
    super.initState();
    _stream = _open();
    if (!_isGroup) {
      _feedbackSub = _queues.watchFeedback(widget.queueId!).listen((list) {
        if (!mounted) return;
        setState(() => _feedback = {for (final f in list) f.entryId: f});
      }, onError: (_) {});
    }
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
      backgroundColor: context.qio.gray100,
      appBar: AppBar(
        backgroundColor: context.qio.surface,
        title: Text(
          _isGroup ? l10n.groupHistoryTitle : l10n.historyTitle,
          style: context.qioText.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: context.qio.textPrimary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: l10n.exportTooltip,
            icon: const Icon(Icons.file_download_outlined),
            enabled: !_exporting,
            onSelected: _onExportSelected,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'csv', child: Text(l10n.exportCsv)),
              PopupMenuItem(value: 'pdf', child: Text(l10n.exportPdf)),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'csv_phone',
                child: Text(l10n.exportCsvWithPhone),
              ),
              PopupMenuItem(
                value: 'pdf_phone',
                child: Text(l10n.exportPdfWithPhone),
              ),
            ],
          ),
        ],
      ),
      body: QioResponsiveBody(
        child: StreamBuilder<_HistoryData>(
          stream: _stream,
          builder: (context, snap) {
            if (snap.hasError) {
              return QioErrorState(
                message: l10n.loadHistoryError,
                onRetry: () => setState(() {
                  _stream = _open();
                }),
              );
            }
            if (!snap.hasData) {
              return const QioSkeletonList(count: 4);
            }
            final data = snap.data!;
            final all = data.entries;
            if (_isGroup) {
              _feedback = {for (final f in data.feedback) f.entryId: f};
              if (widget.groupQueues.isEmpty) {
                return QioEmptyState(
                  icon: Icons.folder_open,
                  title: l10n.groupHistoryNoQueues,
                  message: l10n.groupHistoryNoQueuesHint,
                );
              }
            }
            if (all.isEmpty) {
              return QioEmptyState(
                icon: Icons.history,
                title: l10n.noHistoryYet,
                message: l10n.emptyHistoryHint,
              );
            }
            final filtered = filterHistory(
              all,
              result: _result,
              period: _period,
              now: (widget.clock ?? DateTime.now)(),
            );
            _filtered = filtered;
            _filteredQueues = [
              if (_isGroup)
                for (final e in filtered) data.queueNames[e] ?? '',
            ];
            final shown = _isGroup ? pageOf(filtered, _page) : filtered;
            final metrics = computeHistoryMetrics(filtered);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_isGroup) ...[
                  Text(widget.groupName!, style: context.qioText.heading3),
                  const SizedBox(height: 8),
                  if (data.group!.truncated) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        l10n.groupHistoryTruncated(
                          QueueService.historyFetchLimit,
                          data.group!.truncatedQueueNames.join(', '),
                        ),
                        style: context.qioText.caption,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
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
                        style: context.qioText.caption,
                      ),
                    ),
                  )
                else
                  for (final e in shown)
                    _HistoryTile(
                      entry: e,
                      rating: _feedback[e.id]?.rating,
                      queueName: _isGroup ? data.queueNames[e] : null,
                    ),
                if (shown.length < filtered.length)
                  Center(
                    child: TextButton(
                      key: const ValueKey('history-show-more'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () => setState(() => _page++),
                      child: Text(
                        l10n.groupHistoryShowMore(
                          shown.length,
                          filtered.length,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
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
            for (final p in HistoryPeriod.values.where(
              (p) => p != HistoryPeriod.custom,
            ))
              ChoiceChip(
                label: Text(p.label(l10n)),
                selected: _period == p,
                onSelected: (_) => setState(() {
                  _period = p;
                  _page = 0;
                }),
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
                onSelected: (_) => setState(() {
                  _result = o.value;
                  _page = 0;
                }),
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
          Text(label, style: context.qioText.label),
          const SizedBox(height: 4),
          Text(value, style: context.qioText.heading2),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, this.rating, this.queueName});

  final HistoryEntry entry;
  final int? rating;
  final String? queueName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = entry.isServed
        ? QioColors.success
        : entry.isLeft
        ? context.qio.textSecondary
        : QioColors.error;
    final textColor = entry.isServed
        ? context.qio.statusOpenText
        : entry.isLeft
        ? context.qio.textSecondary
        : context.qio.statusClosedText;
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
    return MergeSemantics(
      child: Padding(
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
                      style: context.qioText.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: context.qioText.caption),
                    if (queueName != null)
                      Text(
                        l10n.historyQueueOrigin(queueName!),
                        style: context.qioText.caption,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: context.qioText.caption.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
