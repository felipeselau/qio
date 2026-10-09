import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/queue.dart';
import '../../screens/history_screen.dart';
import '../../services/group_service.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_palette.dart';
import 'queue_settings_actions.dart';
import 'status_message_dialog.dart';

class QueueCompactMenu extends StatelessWidget {
  const QueueCompactMenu({
    super.key,
    required this.queueId,
    required this.queueName,
    required this.isOwner,
    required this.showSettings,
    required this.onStatus,
    this.menuKey,
    this.queues,
    this.groups,
    this.onQueueGone,
  });

  final String queueId;
  final String queueName;
  final bool isOwner;
  final bool showSettings;
  final void Function(QueueStatus, StatusChange?) onStatus;
  final GlobalKey? menuKey;
  final QueueService? queues;
  final GroupService? groups;
  final VoidCallback? onQueueGone;

  Future<void> _change(BuildContext context, QueueStatus target) async {
    if (target == QueueStatus.open) {
      onStatus(target, null);
      return;
    }
    final change = await showStatusMessageDialog(context, target);
    if (change != null) onStatus(target, change);
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryScreen(
          queueId: queueId,
          queueName: queueName,
          queues: queues,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<Queue>(
      stream: (queues ?? QueueService.instance).watchQueue(queueId),
      builder: (context, snap) {
        final status = snap.data?.status ?? QueueStatus.open;
        return PopupMenuButton<String>(
          key: menuKey,
          tooltip: l10n.moreActions,
          padding: const EdgeInsets.all(12),
          icon: Icon(Icons.more_vert, color: context.qio.gray700),
          onSelected: (v) {
            switch (v) {
              case 'qr':
              case 'settings':
                openQueueSettings(
                  context,
                  queueId: queueId,
                  queueName: queueName,
                  isOwner: isOwner,
                  queues: queues,
                  groups: groups,
                  onQueueGone: onQueueGone,
                );
              case 'history':
                _openHistory(context);
              case 'reopen':
                onStatus(QueueStatus.open, null);
              case 'pause':
                _change(context, QueueStatus.paused);
              case 'close':
                _change(context, QueueStatus.closed);
            }
          },
          itemBuilder: (_) => [
            if (showSettings)
              PopupMenuItem(value: 'qr', child: Text(l10n.queueQrShortcut)),
            if (showSettings && isOwner)
              PopupMenuItem(
                value: 'settings',
                child: Text(l10n.queueSettingsTitle),
              ),
            if (isOwner)
              PopupMenuItem(value: 'history', child: Text(l10n.historyTitle)),
            if (isOwner && status == QueueStatus.open)
              PopupMenuItem(value: 'pause', child: Text(l10n.pause)),
            if (isOwner && status != QueueStatus.open)
              PopupMenuItem(value: 'reopen', child: Text(l10n.reopen)),
            if (isOwner && status != QueueStatus.closed)
              PopupMenuItem(value: 'close', child: Text(l10n.close)),
          ],
        );
      },
    );
  }
}
