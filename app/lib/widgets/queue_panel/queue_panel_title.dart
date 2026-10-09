import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/queue.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_badge.dart';

class QueuePanelTitle extends StatelessWidget {
  const QueuePanelTitle({
    super.key,
    required this.queueId,
    required this.queueName,
    required this.queues,
  });

  final String queueId;
  final String queueName;
  final QueueService queues;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<Queue>(
      stream: queues.watchQueue(queueId),
      builder: (context, snap) {
        final status = snap.data?.status ?? QueueStatus.open;
        final label = status.label(l10n);
        final badgeStatus = switch (status) {
          QueueStatus.open => QioBadgeStatus.open,
          QueueStatus.paused => QioBadgeStatus.paused,
          QueueStatus.closed => QioBadgeStatus.closed,
        };
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              snap.data?.name ?? queueName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: context.qioText.heading3.copyWith(
                fontWeight: FontWeight.w700,
                color: context.qio.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, constraints) {
                final tight = constraints.maxWidth < 96;
                if (tight) {
                  return Semantics(
                    label: label,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: switch (status) {
                          QueueStatus.open => context.qio.statusOpenText,
                          QueueStatus.paused => context.qio.statusPausedText,
                          QueueStatus.closed => context.qio.statusClosedText,
                        },
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return QioBadge(label: label, status: badgeStatus);
              },
            ),
          ],
        );
      },
    );
  }
}
