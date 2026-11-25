import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/metrics_export.dart';
import '../services/staffing_metrics.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';
import 'bi_bars.dart';
import 'bi_info.dart';
import 'qio_card.dart';

enum StaffingMode { required, observed, gap }

const double _gapTolerance = 0.25;
const double _cellWidth = 30;
const double _cellHeight = 26;
const double _labelWidth = 44;

class StaffingSection extends StatefulWidget {
  const StaffingSection({super.key, required this.report});

  final StaffingReport report;

  @override
  State<StaffingSection> createState() => _StaffingSectionState();
}

class _StaffingSectionState extends State<StaffingSection> {
  StaffingMode _mode = StaffingMode.required;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final grid = widget.report.grid;
    final mode = grid.hasRequirement ? _mode : StaffingMode.observed;
    return Column(
      key: const ValueKey('staffing-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.staffTitle, style: context.qioText.heading3),
        ),
        const SizedBox(height: 4),
        Text(l10n.staffSubtitle, style: context.qioText.caption),
        const SizedBox(height: 8),
        _GridCard(
          grid: grid,
          mode: mode,
          onMode: (m) => setState(() => _mode = m),
        ),
        const SizedBox(height: 12),
        _TopCard(grid: grid),
        const SizedBox(height: 12),
        _SeasonCard(season: widget.report.seasonality),
      ],
    );
  }
}

BiIndicator _indicatorOf(StaffingMode m) => switch (m) {
  StaffingMode.required => BiIndicator.staffingRequired,
  StaffingMode.observed => BiIndicator.staffingObserved,
  StaffingMode.gap => BiIndicator.staffingGap,
};

String _modeLabel(AppLocalizations l10n, StaffingMode m) => switch (m) {
  StaffingMode.required => l10n.staffModeRequired,
  StaffingMode.observed => l10n.staffModeObserved,
  StaffingMode.gap => l10n.staffModeGap,
};

String _cellText(String locale, StaffingCell c, StaffingMode mode) {
  final active = c.required > 0 || c.observed > 0;
  switch (mode) {
    case StaffingMode.required:
      return c.required > 0 ? '${c.required}' : '';
    case StaffingMode.observed:
      return c.observed > 0 ? decimal1(locale, c.observed) : '';
    case StaffingMode.gap:
      if (!active) return '';
      final v = c.gap;
      final text = decimal1(locale, v.abs());
      return v > _gapTolerance
          ? '+$text'
          : v < -_gapTolerance
          ? '-$text'
          : '0';
  }
}

Color _cellColor(BuildContext context, StaffingCell c, bool hasRequirement) {
  if (c.required == 0 && c.observed == 0) return Colors.transparent;
  if (!hasRequirement) return QioColors.info.withValues(alpha: 0.18);
  if (c.gap > _gapTolerance) return QioColors.warning.withValues(alpha: 0.45);
  if (c.gap < -_gapTolerance) {
    return QioColors.success.withValues(alpha: 0.30);
  }
  return QioColors.info.withValues(alpha: 0.18);
}

class _GridCard extends StatelessWidget {
  const _GridCard({
    required this.grid,
    required this.mode,
    required this.onMode,
  });

  final StaffingGrid grid;
  final StaffingMode mode;
  final ValueChanged<StaffingMode> onMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final modes = grid.hasRequirement
        ? StaffingMode.values
        : const [StaffingMode.observed];
    final hint = switch (mode) {
      StaffingMode.required => l10n.staffHintRequired(
        occupancyPct(grid.occupancy),
      ),
      StaffingMode.observed => l10n.staffHintObserved,
      StaffingMode.gap => l10n.staffHintGap,
    };
    return QioCard(
      key: const ValueKey('staffing-grid-card'),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BiTitle(text: l10n.staffGridTitle, indicator: _indicatorOf(mode)),
            const SizedBox(height: 8),
            if (!grid.hasArrivals)
              Text(
                l10n.staffNoData,
                key: const ValueKey('staffing-empty'),
                style: context.qioText.body,
              )
            else ...[
              _ServiceLine(grid: grid),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in modes)
                    ChoiceChip(
                      key: ValueKey('staffing-mode-${m.name}'),
                      label: Text(_modeLabel(l10n, m)),
                      selected: mode == m,
                      onSelected: (_) => onMode(m),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                key: const ValueKey('staffing-hint'),
                style: context.qioText.caption,
              ),
              const SizedBox(height: 8),
              Semantics(
                label: l10n.staffGridSpoken(
                  _modeLabel(l10n, mode),
                  _topSummary(l10n, locale, grid),
                ),
                child: ExcludeSemantics(
                  child: SingleChildScrollView(
                    key: const ValueKey('staffing-grid-scroll'),
                    scrollDirection: Axis.horizontal,
                    child: _Grid(grid: grid, mode: mode, locale: locale),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (grid.hasRequirement)
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _Legend(
                      color: QioColors.warning.withValues(alpha: 0.45),
                      label: l10n.staffLegendDeficit,
                    ),
                    _Legend(
                      color: QioColors.info.withValues(alpha: 0.18),
                      label: l10n.staffLegendOk,
                    ),
                    _Legend(
                      color: QioColors.success.withValues(alpha: 0.30),
                      label: l10n.staffLegendSurplus,
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _topSummary(AppLocalizations l10n, String locale, StaffingGrid grid) {
  if (grid.topDeficits.isEmpty) return l10n.staffTopNone;
  return grid.topDeficits.map((c) => _topRow(l10n, locale, c)).join('. ');
}

String _topRow(AppLocalizations l10n, String locale, StaffingCell c) =>
    l10n.staffTopRow(
      weekdayLongLabel(locale, c.weekday),
      hourLabel(c.hour),
      c.required,
      decimal1(locale, c.observed),
    );

class _ServiceLine extends StatelessWidget {
  const _ServiceLine({required this.grid});

  final StaffingGrid grid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final avg = grid.avgServiceMin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                avg == null
                    ? l10n.staffServiceNone(defaultMinServiceSamples)
                    : l10n.staffServiceTime(
                        decimal1(locale, avg),
                        grid.serviceSamples,
                      ),
                key: const ValueKey('staffing-service'),
                style: context.qioText.body,
              ),
            ),
            const BiInfoButton(indicator: BiIndicator.staffingService),
          ],
        ),
        Text(
          '${l10n.staffOccupancy(occupancyPct(grid.occupancy))} · '
          '${l10n.staffCoverage(grid.coverageDays)}',
          key: const ValueKey('staffing-basis'),
          style: context.qioText.caption,
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: context.qio.gray200),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(child: Text(label, style: context.qioText.caption)),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.grid, required this.mode, required this.locale});

  final StaffingGrid grid;
  final StaffingMode mode;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final style = context.qioText.caption.copyWith(
      fontSize: 11,
      color: context.qio.textPrimary,
    );
    Widget box(Widget child, {Color? color}) => Container(
      width: _cellWidth,
      height: _cellHeight,
      margin: const EdgeInsets.all(1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: child,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: _labelWidth),
            for (var h = 0; h < 24; h++)
              box(
                Text('$h', style: style.copyWith(fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        for (var d = 0; d < 7; d++)
          Row(
            children: [
              SizedBox(
                width: _labelWidth,
                child: Text(
                  weekdayLabel(locale, d),
                  style: style.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              for (var h = 0; h < 24; h++)
                box(
                  Text(
                    _cellText(locale, grid.cells[d][h], mode),
                    key: ValueKey('staffing-cell-$d-$h'),
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                  color: _cellColor(
                    context,
                    grid.cells[d][h],
                    grid.hasRequirement,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _TopCard extends StatelessWidget {
  const _TopCard({required this.grid});

  final StaffingGrid grid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    return QioCard(
      key: const ValueKey('staffing-top-card'),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BiTitle(
              text: l10n.staffTopTitle,
              indicator: BiIndicator.staffingGap,
            ),
            const SizedBox(height: 8),
            if (!grid.hasRequirement || !grid.hasArrivals)
              Text(
                grid.hasArrivals
                    ? l10n.staffServiceNone(defaultMinServiceSamples)
                    : l10n.staffNoData,
                key: const ValueKey('staffing-top-unavailable'),
                style: context.qioText.body,
              )
            else if (grid.topDeficits.isEmpty)
              Text(
                l10n.staffTopNone,
                key: const ValueKey('staffing-top-none'),
                style: context.qioText.body,
              )
            else
              for (var i = 0; i < grid.topDeficits.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: context.qio.statusPausedText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _topRow(l10n, locale, grid.topDeficits[i]),
                          key: ValueKey('staffing-top-$i'),
                          style: context.qioText.body,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  const _SeasonCard({required this.season});

  final SeasonalityReport season;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final weeks = season.weeks;
    final max = weeks.fold<int>(0, (m, w) => w.volume > m ? w.volume : m);
    return QioCard(
      key: const ValueKey('staffing-season-card'),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BiTitle(
              text: l10n.staffSeasonTitle,
              indicator: BiIndicator.seasonVolume,
            ),
            const SizedBox(height: 8),
            if (season.insufficient)
              Text(
                l10n.staffSeasonInsufficient(
                  minSeasonWeeks,
                  season.observedWeeks,
                ),
                key: const ValueKey('staffing-season-insufficient'),
                style: context.qioText.body,
              )
            else ...[
              DayBars(
                key: const ValueKey('staffing-weekly-bars'),
                fractions: [for (final w in weeks) fractionOf(w.volume, max)],
                startLabel: shortDate(locale, weeks.first.weekStart),
                endLabel: shortDate(locale, weeks.last.weekStart),
                semantics: weeks
                    .map(
                      (w) => l10n.staffWeekSpoken(
                        shortDate(locale, w.weekStart),
                        w.volume,
                      ),
                    )
                    .join('. '),
              ),
              const SizedBox(height: 8),
              if (season.trendPct != null)
                Text(
                  switch (season.direction!) {
                    TrendDirection.up => l10n.staffTrendUp(
                      decimal1(locale, season.trendPct!),
                    ),
                    TrendDirection.down => l10n.staffTrendDown(
                      decimal1(locale, season.trendPct!),
                    ),
                    TrendDirection.stable => l10n.staffTrendStable(
                      stableTrendPct.round(),
                    ),
                  },
                  key: const ValueKey('staffing-trend'),
                  style: context.qioText.body,
                ),
              const SizedBox(height: 12),
              BiTitle(
                text: l10n.staffRecurringTitle,
                indicator: BiIndicator.seasonPattern,
              ),
              const SizedBox(height: 4),
              if (season.recurring.isEmpty)
                Text(
                  l10n.staffRecurringNone(recurrencePct),
                  key: const ValueKey('staffing-recurring-none'),
                  style: context.qioText.body,
                )
              else
                for (var i = 0; i < season.recurring.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      l10n.staffRecurringRow(
                        weekdayLongLabel(locale, season.recurring[i].weekday),
                        hourLabel(season.recurring[i].hour),
                        season.recurring[i].weeks,
                        season.recurring[i].observedWeeks,
                      ),
                      key: ValueKey('staffing-recurring-$i'),
                      style: context.qioText.body,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
