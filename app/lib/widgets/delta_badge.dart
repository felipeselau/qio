import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/metrics_trend.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';

bool lowerIsBetter(MetricKey key) => key != MetricKey.total;

class DeltaBadge extends StatelessWidget {
  const DeltaBadge({super.key, required this.metric, required this.delta});

  final MetricKey metric;
  final Delta delta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = metric == MetricKey.noShowRate;
    final value = points ? delta.abs : delta.pct ?? 0;
    final rounded = value.abs().round();
    final up = value > 0;
    final same = rounded == 0;
    final String text;
    final String spoken;
    if (same) {
      text = l10n.deltaSame;
      spoken = '${l10n.deltaSame} ${l10n.deltaVsPrevious}';
    } else {
      final shown = points ? l10n.deltaPoints(rounded) : '$rounded%';
      text = points
          ? '${up ? '▲' : '▼'} $shown'
          : up
          ? l10n.deltaUp(rounded)
          : l10n.deltaDown(rounded);
      spoken =
          '${up ? l10n.deltaRose : l10n.deltaFell} $shown ${l10n.deltaVsPrevious}';
    }
    final Color color;
    if (same) {
      color = QioColors.textSecondary;
    } else {
      final good = lowerIsBetter(metric) ? !up : up;
      color = good ? QioColors.statusOpenText : QioColors.statusClosedText;
    }
    return Semantics(
      label: spoken,
      child: ExcludeSemantics(
        child: Text(
          text,
          style: QioTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
