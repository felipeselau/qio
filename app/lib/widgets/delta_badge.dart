import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../l10n/app_localizations.dart';
import '../services/metrics_trend.dart';
import '../theme/qio_text_styles.dart';
import '../theme/qio_palette.dart';

bool lowerIsBetter(MetricKey key) => key != MetricKey.total;

String _deltaShown(AppLocalizations l10n, double magnitude) => magnitude >= 1
    ? '${magnitude.round()}'
    : NumberFormat('0.0', l10n.localeName).format(magnitude);

String deltaSpoken(AppLocalizations l10n, MetricKey metric, Delta delta) {
  final points = metric == MetricKey.noShowRate;
  final value = points ? delta.abs : delta.pct ?? 0;
  if (value == 0) return '${l10n.deltaSame} ${l10n.deltaVsPrevious}';
  final shown = _deltaShown(l10n, value.abs());
  final spokenValue = points ? l10n.deltaPoints(shown) : '$shown%';
  return '${value > 0 ? l10n.deltaRose : l10n.deltaFell} $spokenValue ${l10n.deltaVsPrevious}';
}

class DeltaBadge extends StatelessWidget {
  const DeltaBadge({super.key, required this.metric, required this.delta});

  final MetricKey metric;
  final Delta delta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = metric == MetricKey.noShowRate;
    final value = points ? delta.abs : delta.pct ?? 0;
    final up = value > 0;
    final same = value == 0;
    final shown = _deltaShown(l10n, value.abs());
    final String text;
    if (same) {
      text = l10n.deltaSame;
    } else {
      text = points
          ? (up ? l10n.deltaPointsUp(shown) : l10n.deltaPointsDown(shown))
          : (up ? l10n.deltaUp(shown) : l10n.deltaDown(shown));
    }
    final Color color;
    if (same) {
      color = context.qio.textSecondary;
    } else {
      final good = lowerIsBetter(metric) ? !up : up;
      color = good ? context.qio.statusOpenText : context.qio.statusClosedText;
    }
    return Semantics(
      label: deltaSpoken(l10n, metric, delta),
      child: ExcludeSemantics(
        child: Text(
          text,
          style: context.qioText.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
