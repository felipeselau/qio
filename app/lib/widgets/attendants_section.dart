import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/attendant_metrics.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';
import 'bi_bars.dart';
import 'bi_info.dart';
import 'qio_card.dart';

enum AttendantColumn { served, service, deviation, rate, idle, noShow, rating }

const _ownerId = '__owner__';
const _allId = '__all__';

String attendantRowId(AttendantRow r) => r.attendantId ?? _ownerId;

double? _sortValue(AttendantRow r, AttendantColumn c) {
  switch (c) {
    case AttendantColumn.served:
      return r.stats.served.toDouble();
    case AttendantColumn.service:
      return r.stats.avgServiceMin;
    case AttendantColumn.deviation:
      return r.deviationPct;
    case AttendantColumn.rate:
      return r.perHour;
    case AttendantColumn.idle:
      return r.idlePct;
    case AttendantColumn.noShow:
      return r.stats.volume == 0 ? null : r.stats.noShow.toDouble();
    case AttendantColumn.rating:
      return r.stats.feedback.average;
  }
}

bool _defaultAscending(AttendantColumn c) =>
    c != AttendantColumn.served &&
    c != AttendantColumn.rate &&
    c != AttendantColumn.rating;

List<AttendantRow> sortAttendantRows(
  List<AttendantRow> rows,
  AttendantColumn column,
  bool ascending,
  String Function(AttendantRow) nameOf,
) {
  final sorted = [...rows];
  sorted.sort((a, b) {
    final va = _sortValue(a, column);
    final vb = _sortValue(b, column);
    if (va == null && vb != null) return 1;
    if (va != null && vb == null) return -1;
    if (va != null && vb != null && va != vb) {
      return ascending ? va.compareTo(vb) : vb.compareTo(va);
    }
    return nameOf(a).compareTo(nameOf(b));
  });
  return sorted;
}

String _columnLabel(AppLocalizations l, AttendantColumn c) {
  switch (c) {
    case AttendantColumn.served:
      return l.cmpColServed;
    case AttendantColumn.service:
      return l.attColService;
    case AttendantColumn.deviation:
      return l.attColDeviation;
    case AttendantColumn.rate:
      return l.attColRate;
    case AttendantColumn.idle:
      return l.attColIdle;
    case AttendantColumn.noShow:
      return l.cmpColNoShow;
    case AttendantColumn.rating:
      return l.cmpColRating;
  }
}

String _columnSpoken(AppLocalizations l, AttendantColumn c) {
  switch (c) {
    case AttendantColumn.served:
      return l.metricsTotal;
    case AttendantColumn.service:
      return l.avgService;
    case AttendantColumn.deviation:
      return l.biNameAttendantDeviation;
    case AttendantColumn.rate:
      return l.biNameAttendantRate;
    case AttendantColumn.idle:
      return l.biNameAttendantIdle;
    case AttendantColumn.noShow:
      return l.noShowPlural;
    case AttendantColumn.rating:
      return l.csvAvgRating;
  }
}

String _minutes(AppLocalizations l, double? v) {
  if (v == null) return '—';
  if (v < 1) return l.durationLessThanMinute;
  return l.durationMinutes(v.round());
}

String deviationText(double? v) {
  if (v == null) return '—';
  final r = v.round();
  return '${r > 0 ? '+' : ''}$r%';
}

String rateText(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)}/h';

String idleText(double? v) => v == null ? '—' : '${(v * 100).round()}%';

String ratingText(AttendantRow r) => r.stats.feedback.average == null
    ? '—'
    : '${r.stats.feedback.average!.toStringAsFixed(1)} ★';

class AttendantsBody extends StatelessWidget {
  const AttendantsBody({super.key, required this.rows, required this.nameOf});

  final List<AttendantRow> rows;
  final String Function(AttendantRow) nameOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AttendantsTable(rows: rows, nameOf: nameOf),
        const SizedBox(height: 8),
        Text(
          l10n.attInsufficientNote(defaultMinRateSamples),
          key: const ValueKey('attendants-note'),
          style: context.qioText.caption,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 0,
          children: [
            for (final i in const [
              BiIndicator.attendantService,
              BiIndicator.attendantDeviation,
              BiIndicator.attendantRate,
              BiIndicator.attendantIdle,
            ])
              _InfoChip(indicator: i),
          ],
        ),
        const SizedBox(height: 16),
        AttendantsChart(rows: rows, nameOf: nameOf),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.indicator});

  final BiIndicator indicator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = biInfoTexts(l10n, indicator).name;
    return TextButton.icon(
      key: ValueKey('info-${indicator.name}'),
      onPressed: () => showBiInfoSheet(context, indicator),
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      icon: const Icon(Icons.info_outline, size: 18),
      label: Text(name),
    );
  }
}

class AttendantsTable extends StatefulWidget {
  const AttendantsTable({super.key, required this.rows, required this.nameOf});

  final List<AttendantRow> rows;
  final String Function(AttendantRow) nameOf;

  @override
  State<AttendantsTable> createState() => _AttendantsTableState();
}

class _AttendantsTableState extends State<AttendantsTable> {
  AttendantColumn _column = AttendantColumn.served;
  bool _ascending = false;

  static const _nameWidth = 140.0;
  static const _cellWidth = 88.0;

  void _sortBy(AttendantColumn c) {
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
    final rows = sortAttendantRows(
      widget.rows,
      _column,
      _ascending,
      widget.nameOf,
    );
    final width = _nameWidth + _cellWidth * AttendantColumn.values.length;
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
            child: Text(l10n.csvAttendant, style: context.qioText.label),
          ),
        ),
        for (final c in AttendantColumn.values)
          SizedBox(width: _cellWidth, child: _headerCell(context, l10n, c)),
      ],
    );
  }

  Widget _headerCell(
    BuildContext context,
    AppLocalizations l10n,
    AttendantColumn c,
  ) {
    final active = _column == c;
    final state = active
        ? ', ${_ascending ? l10n.sortAscending : l10n.sortDescending}'
        : '';
    return Semantics(
      button: true,
      selected: active,
      onTap: () => _sortBy(c),
      label: '${l10n.sortByHint(_columnSpoken(l10n, c))}$state',
      child: ExcludeSemantics(
        child: InkWell(
          key: ValueKey('attendants-sort-${c.name}'),
          onTap: () => _sortBy(c),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _columnLabel(l10n, c),
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

  Widget _row(BuildContext context, AppLocalizations l10n, AttendantRow r) {
    final name = widget.nameOf(r);
    final rating = r.stats.feedback.average == null
        ? '—'
        : '${r.stats.feedback.average!.toStringAsFixed(1)} (${r.stats.feedback.count})';
    final spoken = l10n.attRowSpoken(
      name,
      r.stats.served,
      _minutes(l10n, r.stats.avgServiceMin),
      deviationText(r.deviationPct),
      rateText(r.perHour),
      idleText(r.idlePct),
      r.stats.noShow,
      rating,
    );
    final values = {
      AttendantColumn.served: '${r.stats.served}',
      AttendantColumn.service: _minutes(l10n, r.stats.avgServiceMin),
      AttendantColumn.deviation: deviationText(r.deviationPct),
      AttendantColumn.rate: rateText(r.perHour),
      AttendantColumn.idle: idleText(r.idlePct),
      AttendantColumn.noShow: '${r.stats.noShow}',
      AttendantColumn.rating: ratingText(r),
    };
    return Semantics(
      container: true,
      label: spoken,
      child: ExcludeSemantics(
        child: Container(
          key: ValueKey('attendants-row-${attendantRowId(r)}'),
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
                  child: Text(name, style: context.qioText.bodyMedium),
                ),
              ),
              for (final c in AttendantColumn.values)
                SizedBox(
                  width: _cellWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      values[c]!,
                      key: ValueKey(
                        'attendants-cell-${attendantRowId(r)}-${c.name}',
                      ),
                      style: context.qioText.body,
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

class AttendantsChart extends StatefulWidget {
  const AttendantsChart({super.key, required this.rows, required this.nameOf});

  final List<AttendantRow> rows;
  final String Function(AttendantRow) nameOf;

  @override
  State<AttendantsChart> createState() => _AttendantsChartState();
}

class _AttendantsChartState extends State<AttendantsChart> {
  String _selected = _allId;
  bool _byShift = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedRows = _selected == _allId
        ? widget.rows
        : widget.rows.where((r) => attendantRowId(r) == _selected).toList();
    final effective = selectedRows.isEmpty ? widget.rows : selectedRows;
    final value = selectedRows.isEmpty ? _allId : _selected;
    final byHour = sumByHour(effective);
    final byShift = sumByShift(effective);
    final total = byHour.fold<int>(0, (a, b) => a + b);
    return QioCard(
      key: const ValueKey('attendants-chart'),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _byShift ? l10n.attChartTitleShift : l10n.attChartTitleHour,
                    style: context.qioText.heading3,
                  ),
                ),
                const BiInfoButton(indicator: BiIndicator.attendantThroughput),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              label: l10n.attChartOperatorLabel,
              child: DropdownButton<String>(
                key: const ValueKey('attendants-chart-operator'),
                isExpanded: true,
                value: value,
                onChanged: (v) => setState(() => _selected = v ?? _allId),
                items: [
                  DropdownMenuItem(
                    value: _allId,
                    child: Text(l10n.attChartAll),
                  ),
                  for (final r in widget.rows)
                    DropdownMenuItem(
                      value: attendantRowId(r),
                      child: Text(
                        widget.nameOf(r),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  key: const ValueKey('attendants-mode-hour'),
                  label: Text(l10n.attChartModeHour),
                  selected: !_byShift,
                  onSelected: (_) => setState(() => _byShift = false),
                ),
                ChoiceChip(
                  key: const ValueKey('attendants-mode-shift'),
                  label: Text(l10n.attChartModeShift),
                  selected: _byShift,
                  onSelected: (_) => setState(() => _byShift = true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (total == 0)
              Text(
                l10n.attChartEmpty,
                key: const ValueKey('attendants-chart-empty'),
                style: context.qioText.body,
              )
            else if (_byShift)
              _shiftChart(context, l10n, byShift)
            else
              _hourChart(context, l10n, byHour),
          ],
        ),
      ),
    );
  }

  Widget _hourChart(BuildContext context, AppLocalizations l10n, List<int> v) {
    final max = v.fold<int>(0, (m, x) => x > m ? x : m);
    final peak = v.indexOf(max);
    final summary = l10n.attChartPeak('${peak}h', max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HourBars(
          key: const ValueKey('attendants-hour-bars'),
          fractions: [for (final x in v) fractionOf(x, max)],
          semantics: l10n.attChartSemantics(
            [
              summary,
              for (var h = 0; h < 24; h++)
                if (v[h] > 0) '${h}h: ${v[h]}',
            ].join(', '),
          ),
        ),
        const SizedBox(height: 8),
        Text(summary, style: context.qioText.body),
      ],
    );
  }

  Widget _shiftChart(
    BuildContext context,
    AppLocalizations l10n,
    Map<Shift, int> v,
  ) {
    final labels = {
      Shift.morning: l10n.attShiftMorning,
      Shift.afternoon: l10n.attShiftAfternoon,
      Shift.night: l10n.attShiftNight,
    };
    final max = v.values.fold<int>(0, (m, x) => x > m ? x : m);
    final peak = Shift.values.firstWhere((s) => v[s] == max);
    final summary = l10n.attChartPeak(labels[peak]!, max);
    return Column(
      key: const ValueKey('attendants-shift-bars'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RateBarList(
          prefix: 'attendants-shift',
          items: [
            for (final s in Shift.values)
              RateBarItem(
                id: s.name,
                label: labels[s]!,
                value: '${v[s]}',
                fraction: fractionOf(v[s], max),
                spoken: '${labels[s]}: ${v[s]}',
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(summary, style: context.qioText.body),
      ],
    );
  }
}
