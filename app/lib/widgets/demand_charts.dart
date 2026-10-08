import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../l10n/app_localizations.dart';
import '../services/metrics_export.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import 'qio_card.dart';
import '../theme/qio_palette.dart';

const _levelMix = [0.55, 0.7, 0.85, 1.0];

int heatLevel(int count, int max) =>
    count <= 0 || max <= 0 ? 0 : (4 * count / max).ceil().clamp(1, 4);

Color heatColor(int level, Color empty) => level == 0
    ? empty
    : Color.lerp(empty, QioColors.primary, _levelMix[level - 1])!;

bool _hasDemand(MetricsReport report) =>
    report.weekdays.length == 7 &&
    report.heatmap.length == 7 &&
    report.demandPeak != null;

class DemandCharts extends StatelessWidget {
  const DemandCharts({super.key, required this.report});

  final MetricsReport report;

  @override
  Widget build(BuildContext context) {
    if (!_hasDemand(report)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final names = [for (var d = 0; d < 7; d++) weekdayLabel(locale, d)];
    final summary = demandPeakText(l10n, locale, report.demandPeak!);
    return Column(
      children: [
        const SizedBox(height: 16),
        QioCard(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.weekdayDemandTitle, style: context.qioText.heading3),
                const SizedBox(height: 16),
                _WeekdayChart(
                  counts: report.weekdays,
                  names: names,
                  summary: l10n.weekdayChartSemantics(
                    [
                      for (var d = 0; d < 7; d++)
                        '${names[d]}: ${report.weekdays[d]}',
                    ].join(', '),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        QioCard(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.heatmapTitle, style: context.qioText.heading3),
                const SizedBox(height: 16),
                _HeatmapChart(
                  matrix: report.heatmap,
                  names: names,
                  summary: summary,
                  cellLabel: (d, h, count) =>
                      l10n.heatmapCellSemantics(names[d], hourLabel(h), count),
                ),
                const SizedBox(height: 12),
                _HeatmapLegend(
                  less: l10n.heatmapLegendLess,
                  more: l10n.heatmapLegendMore,
                ),
                const SizedBox(height: 12),
                ExcludeSemantics(
                  child: Text(summary, style: context.qioText.body),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekdayChart extends StatelessWidget {
  const _WeekdayChart({
    required this.counts,
    required this.names,
    required this.summary,
  });

  final List<int> counts;
  final List<String> names;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final max = counts.fold<int>(0, (m, v) => v > m ? v : m);
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
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          height: max == 0 ? 2 : 2 + 98 * counts[d] / max,
                          decoration: BoxDecoration(
                            color: counts[d] == 0
                                ? context.qio.gray200
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
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: Text(
                      names[d],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.qioText.caption,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

typedef _CellLabel = String Function(int weekday, int hour, int count);

class _HeatmapChart extends StatelessWidget {
  const _HeatmapChart({
    required this.matrix,
    required this.names,
    required this.summary,
    required this.cellLabel,
  });

  final List<List<int>> matrix;
  final List<String> names;
  final String summary;
  final _CellLabel cellLabel;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final labelWidth = scaler.scale(34).clamp(34.0, 72.0);
    final rowHeight = scaler.scale(16).clamp(18.0, 36.0);
    final direction = Directionality.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: summary,
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: labelWidth),
              Expanded(
                child: ExcludeSemantics(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final cellW = c.maxWidth / 24;
                      return SizedBox(
                        height: rowHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (final h in const [0, 6, 12, 18, 23])
                              Positioned(
                                left: h == 23 ? null : h * cellW,
                                right: h == 23 ? 0 : null,
                                child: Text(
                                  hourLabel(h),
                                  style: context.qioText.caption,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: labelWidth,
                  child: Column(
                    children: [
                      for (var d = 0; d < 7; d++)
                        SizedBox(
                          height: rowHeight,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              names[d],
                              style: context.qioText.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: rowHeight * 7,
                  child: CustomPaint(
                    painter: _HeatmapPainter(
                      matrix: matrix,
                      emptyColor: context.qio.gray200,
                      borderColor: context.qio.gray300,
                      textDirection: direction,
                      cellLabel: cellLabel,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.matrix,
    required this.emptyColor,
    required this.borderColor,
    required this.textDirection,
    required this.cellLabel,
  });

  final List<List<int>> matrix;
  final Color emptyColor;
  final Color borderColor;
  final TextDirection textDirection;
  final _CellLabel cellLabel;

  int get _max {
    var m = 0;
    for (final row in matrix) {
      for (final c in row) {
        if (c > m) m = c;
      }
    }
    return m;
  }

  Rect _cell(Size size, int d, int h) {
    final w = size.width / 24;
    final hh = size.height / 7;
    return Rect.fromLTWH(h * w, d * hh, w, hh).deflate(1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final max = _max;
    final paint = Paint();
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = borderColor;
    for (var d = 0; d < 7; d++) {
      for (var h = 0; h < 24; h++) {
        final count = matrix[d][h];
        final level = heatLevel(count, max);
        paint.color = heatColor(level, emptyColor);
        final rrect = RRect.fromRectAndRadius(
          _cell(size, d, h),
          const Radius.circular(2),
        );
        canvas.drawRRect(rrect, paint);
        if (level == 0) canvas.drawRRect(rrect, border);
      }
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (var d = 0; d < 7; d++)
          for (var h = 0; h < 24; h++)
            if (matrix[d][h] > 0)
              CustomPainterSemantics(
                key: ValueKey('heatmap-$d-$h'),
                rect: _cell(size, d, h),
                properties: SemanticsProperties(
                  label: cellLabel(d, h, matrix[d][h]),
                  textDirection: textDirection,
                ),
              ),
      ];

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.matrix != matrix ||
      old.emptyColor != emptyColor ||
      old.borderColor != borderColor;

  @override
  bool shouldRebuildSemantics(_HeatmapPainter old) =>
      old.matrix != matrix || old.textDirection != textDirection;
}

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend({required this.less, required this.more});

  final String less;
  final String more;

  @override
  Widget build(BuildContext context) {
    final empty = context.qio.gray200;
    Widget swatch(int level) => Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: heatColor(level, empty),
        borderRadius: BorderRadius.circular(2),
        border: level == 0 ? Border.all(color: context.qio.gray300) : null,
      ),
    );
    return ExcludeSemantics(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(less, style: context.qioText.caption),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (var l = 0; l <= 4; l++) swatch(l)],
          ),
          Text(more, style: context.qioText.caption),
        ],
      ),
    );
  }
}
