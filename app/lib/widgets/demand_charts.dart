import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../l10n/app_localizations.dart';
import '../services/metrics_export.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import 'qio_card.dart';

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
                Text(l10n.weekdayDemandTitle, style: QioTextStyles.heading3),
                const SizedBox(height: 16),
                _WeekdayChart(counts: report.weekdays, names: names),
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
                Text(l10n.heatmapTitle, style: QioTextStyles.heading3),
                const SizedBox(height: 16),
                _HeatmapChart(
                  matrix: report.heatmap,
                  names: names,
                  summary: summary,
                  cellLabel: (d, h, count) =>
                      l10n.heatmapCellSemantics(names[d], hourLabel(h), count),
                ),
                const SizedBox(height: 12),
                ExcludeSemantics(
                  child: Text(summary, style: QioTextStyles.body),
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
  const _WeekdayChart({required this.counts, required this.names});

  final List<int> counts;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final max = counts.fold<int>(0, (m, v) => v > m ? v : m);
    return Semantics(
      label: [
        for (var d = 0; d < 7; d++) '${names[d]}: ${counts[d]}',
      ].join(', '),
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
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: Text(
                      names[d],
                      textAlign: TextAlign.center,
                      style: QioTextStyles.caption,
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

  static const double _rowHeight = 18;
  static const double _labelWidth = 36;

  final List<List<int>> matrix;
  final List<String> names;
  final String summary;
  final _CellLabel cellLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: summary,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: _labelWidth),
              Expanded(
                child: ExcludeSemantics(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final cellW = c.maxWidth / 24;
                      return SizedBox(
                        height: 16,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (final h in const [0, 6, 12, 18, 23])
                              Positioned(
                                left: h == 23 ? null : h * cellW,
                                right: h == 23 ? 0 : null,
                                child: Text(
                                  '${h}h',
                                  style: QioTextStyles.caption,
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
                  width: _labelWidth,
                  child: Column(
                    children: [
                      for (var d = 0; d < 7; d++)
                        SizedBox(
                          height: _rowHeight,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              names[d],
                              style: QioTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: _rowHeight * 7,
                  child: CustomPaint(
                    painter: _HeatmapPainter(
                      matrix: matrix,
                      emptyColor: QioColors.gray200,
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
    required this.cellLabel,
  });

  final List<List<int>> matrix;
  final Color emptyColor;
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
    for (var d = 0; d < 7; d++) {
      for (var h = 0; h < 24; h++) {
        final count = matrix[d][h];
        paint.color = count == 0 || max == 0
            ? emptyColor
            : QioColors.primary.withValues(alpha: 0.2 + 0.8 * count / max);
        canvas.drawRRect(
          RRect.fromRectAndRadius(_cell(size, d, h), const Radius.circular(2)),
          paint,
        );
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
                  textDirection: TextDirection.ltr,
                ),
              ),
      ];

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.matrix != matrix || old.emptyColor != emptyColor;

  @override
  bool shouldRebuildSemantics(_HeatmapPainter old) => old.matrix != matrix;
}
