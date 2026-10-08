import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/queue_analytics.dart';
import '../theme/qio_text_styles.dart';
import 'qio_card.dart';

class GroupCompareSection extends StatelessWidget {
  const GroupCompareSection({super.key, required this.rows});

  final List<QueueComparison> rows;

  static String _minutes(AppLocalizations l10n, double? v) {
    if (v == null) return '—';
    if (v < 1) return l10n.durationLessThanMinute;
    return l10n.durationMinutes(v.round());
  }

  static String line(AppLocalizations l10n, QueueComparison r) {
    final avg = r.feedback.average;
    return l10n.groupCompareLine(
      r.metrics.total,
      _minutes(l10n, r.metrics.avgWaitMin),
      (r.metrics.noShowRate * 100).round(),
      avg == null ? '—' : '${avg.toStringAsFixed(1)} ★',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.groupCompareTitle, style: QioTextStyles.heading3),
        const SizedBox(height: 8),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              label: '${r.name}. ${line(l10n, r)}',
              child: ExcludeSemantics(
                child: SizedBox(
                  width: double.infinity,
                  child: QioCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: QioTextStyles.bodyMedium),
                        const SizedBox(height: 2),
                        Text(line(l10n, r), style: QioTextStyles.caption),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
