import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/queue_analytics.dart';
import '../theme/qio_text_styles.dart';
import 'comparison_table.dart';

class GroupOverviewSection extends StatelessWidget {
  const GroupOverviewSection({
    super.key,
    required this.rows,
    required this.onSelect,
  });

  final List<GroupComparison> rows;
  final ValueChanged<MetricsScope> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.groupOverviewTitle, style: context.qioText.heading3),
        const SizedBox(height: 2),
        Text(l10n.groupOverviewHint, style: context.qioText.caption),
        const SizedBox(height: 8),
        ComparisonTable(
          firstColumnLabel: l10n.cmpColGroup,
          rows: [
            for (final r in rows)
              ComparisonRow(
                id: r.groupId ?? 'none',
                name: r.groupId == null ? l10n.groupNone : r.name,
                subtitle: l10n.metricsGroupQueues(r.queueCount),
                stats: r,
                pinLast: r.groupId == null,
                onTap: () => onSelect(
                  r.groupId == null
                      ? MetricsScope.ungrouped
                      : MetricsScope.group(r.groupId!),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
