import 'package:flutter/material.dart';
import 'status_message_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../models/queue.dart';
import '../../services/queue_service.dart';
import '../../widgets/queue_panel/status_button.dart';
import '../../screens/history_screen.dart';
import '../../theme/qio_palette.dart';

class QueueStatusActions extends StatelessWidget {
  const QueueStatusActions({
    super.key,
    required this.queueId,
    required this.queueName,
    required this.onStatus,
    this.queues,
  });

  final String queueId;
  final String queueName;
  final void Function(QueueStatus, StatusChange?) onStatus;
  final QueueService? queues;

  Future<void> _change(BuildContext context, QueueStatus target) async {
    if (target == QueueStatus.open) {
      onStatus(target, null);
      return;
    }
    final change = await showStatusMessageDialog(context, target);
    if (change != null) onStatus(target, change);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.history, color: context.qio.gray700),
          tooltip: l10n.historyTitle,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HistoryScreen(
                queueId: queueId,
                queueName: queueName,
                queues: queues,
              ),
            ),
          ),
        ),
        StreamBuilder<Queue>(
          stream: (queues ?? QueueService.instance).watchQueue(queueId),
          builder: (context, snap) {
            final q = snap.data;
            final status = q?.status ?? QueueStatus.open;
            if (status == QueueStatus.closed) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: StatusButton(
                  label: l10n.reopen,
                  color: context.qio.primaryText,
                  onPressed: () => onStatus(QueueStatus.open, null),
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
                  color: context.qio.statusPausedText,
                  onPressed: () => _change(
                    context,
                    status == QueueStatus.paused
                        ? QueueStatus.open
                        : QueueStatus.paused,
                  ),
                ),
                const SizedBox(width: 8),
                StatusButton(
                  label: l10n.close,
                  color: context.qio.statusClosedText,
                  onPressed: () => _change(context, QueueStatus.closed),
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
