import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../screens/queue_settings_screen.dart';
import '../../services/group_service.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_palette.dart';

class QueueSettingsActions extends StatelessWidget {
  const QueueSettingsActions({
    super.key,
    required this.queueId,
    required this.queueName,
    required this.isOwner,
    this.qrKey,
    this.settingsKey,
    this.queues,
    this.groups,
    this.onQueueGone,
  });

  final String queueId;
  final String queueName;
  final bool isOwner;
  final GlobalKey? qrKey;
  final GlobalKey? settingsKey;
  final QueueService? queues;
  final GroupService? groups;
  final VoidCallback? onQueueGone;

  Future<void> _open(BuildContext context) async {
    final exit = await Navigator.of(context).push<QueueSettingsExit>(
      MaterialPageRoute<QueueSettingsExit>(
        builder: (_) => QueueSettingsScreen(
          queueId: queueId,
          queueName: queueName,
          isOwner: isOwner,
          queues: queues,
          groups: groups,
        ),
      ),
    );
    if (exit == QueueSettingsExit.queueGone) onQueueGone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: qrKey,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Icon(Icons.qr_code_2, color: context.qio.gray700),
          tooltip: l10n.queueQrShortcut,
          onPressed: () => _open(context),
        ),
        if (isOwner)
          IconButton(
            key: settingsKey,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(Icons.settings_outlined, color: context.qio.gray700),
            tooltip: l10n.queueSettingsTitle,
            onPressed: () => _open(context),
          ),
      ],
    );
  }
}
