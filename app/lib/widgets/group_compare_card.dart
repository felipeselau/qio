import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/queue_analytics.dart';
import '../theme/qio_text_styles.dart';
import 'comparison_table.dart';

class GroupCompareSection extends StatelessWidget {
  const GroupCompareSection({super.key, required this.rows});

  final List<QueueComparison> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.groupCompareTitle, style: context.qioText.heading3),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 8),
          ComparisonTable(
            firstColumnLabel: l10n.cmpColQueue,
            rows: [
              for (final r in rows)
                ComparisonRow(id: r.queueId, name: r.name, stats: r),
            ],
          ),
        ],
      ],
    );
  }
}
