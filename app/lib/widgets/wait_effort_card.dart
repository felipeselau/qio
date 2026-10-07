import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/history_metrics.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import 'qio_card.dart';

class WaitEffortCard extends StatelessWidget {
  const WaitEffortCard({
    super.key,
    required this.waitStats,
    required this.callEffort,
  });

  final WaitStats waitStats;
  final CallEffortStats callEffort;

  static String _minutes(AppLocalizations l10n, double? v) {
    if (v == null) return '—';
    if (v < 1) return l10n.durationLessThanMinute;
    return l10n.durationMinutes(v.round());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.waitBucketUnder5,
      l10n.waitBucket5to15,
      l10n.waitBucket15to30,
      l10n.waitBucketOver30,
    ];
    final rate = callEffort.recallRate;
    final recalls = rate == null
        ? '—'
        : l10n.recallsStat(callEffort.recallsTotal, (rate * 100).round());
    final skips = callEffort.called == 0
        ? '—'
        : l10n.skipsStat(callEffort.skipsTotal, callEffort.called);
    return QioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.waitDistributionTitle, style: QioTextStyles.heading3),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(
                label: l10n.medianWait,
                value: _minutes(l10n, waitStats.medianMin),
              ),
              _Stat(
                label: l10n.p90Wait,
                value: _minutes(l10n, waitStats.p90Min),
              ),
            ],
          ),
          if (waitStats.samples > 0) ...[
            const SizedBox(height: 16),
            for (var i = 0; i < labels.length; i++)
              _BucketBar(
                label: labels[i],
                count: waitStats.bucketCounts[i],
                total: waitStats.samples,
              ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(label: l10n.recallsTitle, value: recalls),
              _Stat(label: l10n.skipsTitle, value: skips),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: QioTextStyles.label),
          const SizedBox(height: 4),
          Text(value, style: QioTextStyles.heading2),
        ],
      ),
    );
  }
}

class _BucketBar extends StatelessWidget {
  const _BucketBar({
    required this.label,
    required this.count,
    required this.total,
  });

  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    final text = '$count (${(fraction * 100).round()}%)';
    return Semantics(
      label: '$label: $text',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(label, style: QioTextStyles.caption),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 10,
                    backgroundColor: QioColors.gray200,
                    color: QioColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: Text(
                  text,
                  textAlign: TextAlign.end,
                  style: QioTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
