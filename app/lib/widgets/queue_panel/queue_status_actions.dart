import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/queue.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_colors.dart';
import '../../widgets/queue_panel/status_button.dart';
import '../../screens/history_screen.dart';

class QueueStatusActions extends StatelessWidget {
  const QueueStatusActions({
    super.key,
    required this.queueId,
    required this.queueName,
    required this.onStatus,
  });

  final String queueId;
  final String queueName;
  final void Function(QueueStatus) onStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.history, color: QioColors.gray700),
          tooltip: l10n.historyTitle,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  HistoryScreen(queueId: queueId, queueName: queueName),
            ),
          ),
        ),
        StreamBuilder<Queue>(
          stream: QueueService.instance.watchQueue(queueId),
          builder: (context, snap) {
            final q = snap.data;
            final status = q?.status ?? QueueStatus.open;
            if (status == QueueStatus.closed) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: StatusButton(
                  label: l10n.reopen,
                  color: QioColors.primaryText,
                  onPressed: () => onStatus(QueueStatus.open),
                ),
              );
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusButton(
                  label: status == QueueStatus.paused
                      ? l10n.reopen
                      : l10n.pause,
                  color: QioColors.statusPausedText,
                  onPressed: () => onStatus(
                    status == QueueStatus.paused
                        ? QueueStatus.open
                        : QueueStatus.paused,
                  ),
                ),
                const SizedBox(width: 8),
                StatusButton(
                  label: l10n.close,
                  color: QioColors.statusClosedText,
                  onPressed: () => onStatus(QueueStatus.closed),
                ),
                const SizedBox(width: 12),
              ],
            );
          },
        ),
      ],
    );
  }
}
