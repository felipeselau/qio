import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../l10n/app_localizations.dart';
import '../services/metrics_trend.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';

enum TrendLine { wait, noShow }

String trendSummaryText(AppLocalizations l10n, List<DayPoint> series) {
  final stats = trendStats(series);
  final peak = stats.peak;
  if (peak == null) return l10n.noPeakData;
  final locale = l10n.localeName;
  return l10n.trendSummary(
    NumberFormat('0.0', locale).format(stats.avg),
    DateFormat.Md(locale).format(peak.day),
  );
}

class TrendChart extends StatefulWidget {
  const TrendChart({super.key, required this.series});

  final List<DayPoint> series;

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  TrendLine _line = TrendLine.wait;

  Color get _lineColor => _line == TrendLine.wait
      ? QioColors.statusPausedText
      : QioColors.statusClosedText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final series = widget.series;
    final summary = trendSummaryText(l10n, series);
    final values = [
      for (final p in series)
        _line == TrendLine.wait ? p.avgWaitMin : p.noShowRate * 100,
    ];
    final lineLabel = _line == TrendLine.wait
        ? l10n.trendSeriesWait
        : l10n.trendSeriesNoShow;
    final dateFormat = DateFormat.Md(l10n.localeName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<TrendLine>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: TrendLine.wait,
              label: Text(l10n.trendSeriesWait),
            ),
            ButtonSegment(
              value: TrendLine.noShow,
              label: Text(l10n.trendSeriesNoShow),
            ),
          ],
          selected: {_line},
          onSelectionChanged: (s) => setState(() => _line = s.first),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendPainter(
              totals: [for (final p in series) p.total],
              values: values,
              barColor: QioColors.primary,
              emptyBarColor: QioColors.gray200,
              lineColor: _lineColor,
              summary: summary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (series.isNotEmpty)
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(series.first.day),
                  style: QioTextStyles.caption,
                ),
                if (series.length > 1)
                  Text(
                    dateFormat.format(series.last.day),
                    style: QioTextStyles.caption,
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _Legend(color: QioColors.primary, label: l10n.trendSeriesTotal),
            _Legend(color: _lineColor, label: lineLabel),
          ],
        ),
        const SizedBox(height: 8),
        ExcludeSemantics(child: Text(summary, style: QioTextStyles.body)),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: QioTextStyles.caption),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.totals,
    required this.values,
    required this.barColor,
    required this.emptyBarColor,
    required this.lineColor,
    required this.summary,
  });

  final List<int> totals;
  final List<double?> values;
  final Color barColor;
  final Color emptyBarColor;
  final Color lineColor;
  final String summary;

  @override
  void paint(Canvas canvas, Size size) {
    final n = totals.length;
    if (n == 0) return;
    final slot = size.width / n;
    final gap = slot > 6 ? 2.0 : 0.5;
    final barWidth = (slot - gap).clamp(1.0, 40.0);
    final maxTotal = totals.fold<int>(0, (m, v) => v > m ? v : m);
    final bar = Paint();
    for (var i = 0; i < n; i++) {
      final h = maxTotal == 0
          ? 2.0
          : 2 + (size.height - 2) * totals[i] / maxTotal;
      final cx = slot * i + slot / 2;
      bar.color = totals[i] == 0 ? emptyBarColor : barColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - barWidth / 2, size.height - h, barWidth, h),
          const Radius.circular(2),
        ),
        bar,
      );
    }
    final maxValue = values.fold<double>(
      0,
      (m, v) => v != null && v > m ? v : m,
    );
    if (maxValue <= 0) return;
    final stroke = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = lineColor;
    final path = Path();
    var open = false;
    for (var i = 0; i < n; i++) {
      final v = values[i];
      if (v == null) {
        open = false;
        continue;
      }
      final x = slot * i + slot / 2;
      final y = size.height - (size.height - 4) * v / maxValue - 2;
      if (open) {
        path.lineTo(x, y);
      } else {
        path.moveTo(x, y);
        open = true;
      }
      canvas.drawCircle(Offset(x, y), 2.5, dot);
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.totals != totals ||
      old.values != values ||
      old.barColor != barColor ||
      old.emptyBarColor != emptyBarColor ||
      old.lineColor != lineColor;

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        CustomPainterSemantics(
          rect: Offset.zero & size,
          properties: SemanticsProperties(
            label: summary,
            textDirection: TextDirection.ltr,
          ),
        ),
      ];

  @override
  bool shouldRebuildSemantics(_TrendPainter old) => old.summary != summary;
}
