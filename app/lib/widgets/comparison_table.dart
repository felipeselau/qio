import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/metrics_trend.dart';
import '../services/queue_analytics.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';
import 'delta_badge.dart';
import 'qio_card.dart';

enum ComparisonColumn { served, wait, median, p90, noShow, rating }

class ComparisonRow {
  const ComparisonRow({
    required this.id,
    required this.name,
    required this.stats,
    this.subtitle,
    this.onTap,
    this.pinLast = false,
  });

  final String id;
  final String name;
  final String? subtitle;
  final ComparisonStats stats;
  final VoidCallback? onTap;
  final bool pinLast;
}

String comparisonMinutes(AppLocalizations l10n, double? v) {
  if (v == null) return '—';
  if (v < 1) return l10n.durationLessThanMinute;
  return l10n.durationMinutes(v.round());
}

String _rating(ComparisonStats s) => s.feedback.average == null
    ? '—'
    : '${s.feedback.average!.toStringAsFixed(1)} ★';

String _columnLabel(AppLocalizations l10n, ComparisonColumn c) {
  switch (c) {
    case ComparisonColumn.served:
      return l10n.cmpColServed;
    case ComparisonColumn.wait:
      return l10n.cmpColWait;
    case ComparisonColumn.median:
      return l10n.medianWait;
    case ComparisonColumn.p90:
      return l10n.p90Wait;
    case ComparisonColumn.noShow:
      return l10n.cmpColNoShow;
    case ComparisonColumn.rating:
      return l10n.cmpColRating;
  }
}

String _columnSpokenLabel(AppLocalizations l10n, ComparisonColumn c) {
  switch (c) {
    case ComparisonColumn.served:
      return l10n.metricsTotal;
    case ComparisonColumn.wait:
      return l10n.avgWait;
    case ComparisonColumn.noShow:
      return l10n.noShowPlural;
    case ComparisonColumn.rating:
      return l10n.csvAvgRating;
    case ComparisonColumn.median:
    case ComparisonColumn.p90:
      return _columnLabel(l10n, c);
  }
}

MetricKey? _deltaKey(ComparisonColumn c) {
  switch (c) {
    case ComparisonColumn.served:
      return MetricKey.total;
    case ComparisonColumn.wait:
      return MetricKey.avgWait;
    case ComparisonColumn.median:
      return MetricKey.waitMedian;
    case ComparisonColumn.p90:
      return MetricKey.waitP90;
    case ComparisonColumn.noShow:
      return MetricKey.noShowRate;
    case ComparisonColumn.rating:
      return null;
  }
}

double? _sortValue(ComparisonStats s, ComparisonColumn c) {
  switch (c) {
    case ComparisonColumn.served:
      return s.metrics.total.toDouble();
    case ComparisonColumn.wait:
      return s.metrics.avgWaitMin;
    case ComparisonColumn.median:
      return s.waitStats.medianMin;
    case ComparisonColumn.p90:
      return s.waitStats.p90Min;
    case ComparisonColumn.noShow:
      return s.metrics.total == 0 ? null : s.metrics.noShowRate;
    case ComparisonColumn.rating:
      return s.feedback.average;
  }
}

bool _defaultAscending(ComparisonColumn c) =>
    c != ComparisonColumn.served && c != ComparisonColumn.rating;

List<ComparisonRow> sortComparisonRows(
  List<ComparisonRow> rows,
  ComparisonColumn column,
  bool ascending,
) {
  final sorted = [...rows];
  sorted.sort((a, b) {
    final va = _sortValue(a.stats, column);
    final vb = _sortValue(b.stats, column);
    if (va == null && vb != null) return 1;
    if (va != null && vb == null) return -1;
    if (va != null && vb != null && va != vb) {
      return ascending ? va.compareTo(vb) : vb.compareTo(va);
    }
    if (a.pinLast != b.pinLast) return a.pinLast ? 1 : -1;
    return a.name.compareTo(b.name);
  });
  return sorted;
}

String comparisonSpoken(
  AppLocalizations l10n,
  ComparisonStats s, {
  bool withDeltas = true,
}) {
  final m = s.metrics;
  final parts = <String>[
    l10n.groupCompareLine(
      m.total,
      comparisonMinutes(l10n, m.avgWaitMin),
      (m.noShowRate * 100).round(),
      _rating(s),
    ),
    '${l10n.medianWait} ${comparisonMinutes(l10n, s.waitStats.medianMin)}, '
        '${l10n.p90Wait} ${comparisonMinutes(l10n, s.waitStats.p90Min)}',
    if (s.partial) l10n.groupPartialData,
  ];
  if (withDeltas) {
    for (final c in ComparisonColumn.values) {
      final key = _deltaKey(c);
      final delta = key == null ? null : s.deltas[key];
      if (key != null && delta != null) {
        parts.add(
          '${_columnSpokenLabel(l10n, c)} ${deltaSpoken(l10n, key, delta)}',
        );
      }
    }
  }
  return parts.join('. ');
}

class ComparisonTable extends StatefulWidget {
  const ComparisonTable({
    super.key,
    required this.firstColumnLabel,
    required this.rows,
  });

  final String firstColumnLabel;
  final List<ComparisonRow> rows;

  @override
  State<ComparisonTable> createState() => _ComparisonTableState();
}

class _ComparisonTableState extends State<ComparisonTable> {
  ComparisonColumn _column = ComparisonColumn.served;
  bool _ascending = false;

  static const _nameWidth = 140.0;
  static const _cellWidth = 88.0;

  void _sortBy(ComparisonColumn c) {
    setState(() {
      if (_column == c) {
        _ascending = !_ascending;
      } else {
        _column = c;
        _ascending = _defaultAscending(c);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = sortComparisonRows(widget.rows, _column, _ascending);
    final width = _nameWidth + _cellWidth * ComparisonColumn.values.length;
    return QioCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width > constraints.maxWidth ? width : constraints.maxWidth,
            child: Column(
              children: [
                _header(context, l10n),
                for (final r in rows) _row(context, l10n, r),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        SizedBox(
          width: _nameWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(widget.firstColumnLabel, style: context.qioText.label),
          ),
        ),
        for (final c in ComparisonColumn.values)
          SizedBox(width: _cellWidth, child: _headerCell(context, l10n, c)),
      ],
    );
  }

  Widget _headerCell(
    BuildContext context,
    AppLocalizations l10n,
    ComparisonColumn c,
  ) {
    final active = _column == c;
    final label = _columnLabel(l10n, c);
    final state = active
        ? ', ${_ascending ? l10n.sortAscending : l10n.sortDescending}'
        : '';
    return Semantics(
      button: true,
      selected: active,
      label: '${l10n.sortByHint(_columnSpokenLabel(l10n, c))}$state',
      child: ExcludeSemantics(
        child: InkWell(
          key: ValueKey('cmp-sort-${c.name}'),
          onTap: () => _sortBy(c),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: context.qioText.label.copyWith(
                        fontWeight: active ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
                  if (active)
                    Icon(
                      _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: context.qio.textPrimary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, AppLocalizations l10n, ComparisonRow r) {
    final spoken = [
      r.name,
      ?r.subtitle,
      comparisonSpoken(l10n, r.stats),
    ].join('. ');
    return Semantics(
      label: spoken,
      button: r.onTap != null,
      onTapHint: r.onTap == null ? null : l10n.groupOverviewOpenHint,
      child: ExcludeSemantics(
        child: InkWell(
          key: ValueKey('cmp-row-${r.id}'),
          onTap: r.onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.qio.gray200)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _nameWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: context.qioText.bodyMedium),
                        if (r.subtitle != null)
                          Text(r.subtitle!, style: context.qioText.caption),
                        if (r.stats.partial)
                          Text(
                            l10n.groupPartialData,
                            style: context.qioText.caption.copyWith(
                              color: context.qio.statusClosedText,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                for (final c in ComparisonColumn.values)
                  SizedBox(
                    width: _cellWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _cell(context, l10n, r.stats, c),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    AppLocalizations l10n,
    ComparisonStats s,
    ComparisonColumn c,
  ) {
    final String value;
    switch (c) {
      case ComparisonColumn.served:
        value = '${s.metrics.total}';
      case ComparisonColumn.wait:
        value = comparisonMinutes(l10n, s.metrics.avgWaitMin);
      case ComparisonColumn.median:
        value = comparisonMinutes(l10n, s.waitStats.medianMin);
      case ComparisonColumn.p90:
        value = comparisonMinutes(l10n, s.waitStats.p90Min);
      case ComparisonColumn.noShow:
        value = s.metrics.total == 0
            ? '—'
            : '${(s.metrics.noShowRate * 100).round()}%';
      case ComparisonColumn.rating:
        value = _rating(s);
    }
    final key = _deltaKey(c);
    final delta = key == null ? null : s.deltas[key];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: context.qioText.body),
        if (key != null && delta != null)
          DeltaBadge(metric: key, delta: delta)
        else if (c == ComparisonColumn.served)
          Text('—', style: context.qioText.caption),
      ],
    );
  }
}
