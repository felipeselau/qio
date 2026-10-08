import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../l10n/app_localizations.dart';
import '../services/metrics_trend.dart';
import '../theme/qio_text_styles.dart';
import '../theme/qio_palette.dart';

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
    final magnitude = value.abs();
    final up = value > 0;
    final same = value == 0;
    final shown = magnitude >= 1
        ? '${magnitude.round()}'
        : NumberFormat('0.0', l10n.localeName).format(magnitude);
    final String text;
    final String spoken;
    if (same) {
      text = l10n.deltaSame;
      spoken = '${l10n.deltaSame} ${l10n.deltaVsPrevious}';
    } else {
      final spokenValue = points ? l10n.deltaPoints(shown) : '$shown%';
      text = points
          ? (up ? l10n.deltaPointsUp(shown) : l10n.deltaPointsDown(shown))
          : (up ? l10n.deltaUp(shown) : l10n.deltaDown(shown));
      spoken =
          '${up ? l10n.deltaRose : l10n.deltaFell} $spokenValue ${l10n.deltaVsPrevious}';
    }
    final Color color;
    if (same) {
      color = context.qio.textSecondary;
    } else {
      final good = lowerIsBetter(metric) ? !up : up;
      color = good ? context.qio.statusOpenText : context.qio.statusClosedText;
    }
    return Semantics(
      label: spoken,
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
