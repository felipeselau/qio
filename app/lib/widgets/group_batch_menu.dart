import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/queue.dart';
import '../services/action_errors.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import 'queue_panel/status_message_dialog.dart';

enum GroupBatchAction {
  pause(QueueStatus.paused),
  close(QueueStatus.closed),
  reopen(QueueStatus.open);

  const GroupBatchAction(this.target);

  final QueueStatus target;
}

List<GroupBatchAction> availableBatchActions(Iterable<Queue> queues) => [
  if (queues.any((q) => q.status != QueueStatus.paused)) GroupBatchAction.pause,
  if (queues.any((q) => q.status != QueueStatus.closed)) GroupBatchAction.close,
  if (queues.any((q) => q.status != QueueStatus.open)) GroupBatchAction.reopen,
];

const _applyAlerts = Object();

class GroupBatchMenu extends StatelessWidget {
  const GroupBatchMenu({
    super.key,
    required this.groupName,
    required this.queues,
    required this.enabled,
    required this.onSelected,
    required this.onApplyAlerts,
  });

  final String groupName;
  final List<Queue> queues;
  final bool enabled;
  final ValueChanged<GroupBatchAction> onSelected;
  final VoidCallback onApplyAlerts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = availableBatchActions(queues);
    String label(GroupBatchAction a) => switch (a) {
      GroupBatchAction.pause => l10n.groupPauseAll,
      GroupBatchAction.close => l10n.groupCloseAll,
      GroupBatchAction.reopen => l10n.groupReopenAll,
    };
    return PopupMenuButton<Object>(
      tooltip: l10n.groupBatchMenuLabel(groupName),
      enabled: enabled,
      padding: EdgeInsets.zero,
      onSelected: (v) {
        if (v is GroupBatchAction) {
          onSelected(v);
        } else {
          onApplyAlerts();
        }
      },
      itemBuilder: (_) => [
        for (final a in actions)
          PopupMenuItem<Object>(value: a, height: 48, child: Text(label(a))),
        PopupMenuItem<Object>(
          key: const ValueKey('group-apply-alerts'),
          value: _applyAlerts,
          height: 48,
          child: Text(l10n.groupApplyAlerts),
        ),
      ],
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.more_vert),
      ),
    );
  }
}

Future<void> runGroupBatch(
  BuildContext context, {
  required QueueService service,
  required String groupId,
  required String groupName,
  required int count,
  required GroupBatchAction action,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  StatusChange? change;
  if (action != GroupBatchAction.reopen) {
    change = await showStatusMessageDialog(context, action.target);
    if (change == null || !context.mounted) return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(switch (action) {
        GroupBatchAction.pause => l10n.groupBatchConfirmPause(count, groupName),
        GroupBatchAction.close => l10n.groupBatchConfirmClose(count, groupName),
        GroupBatchAction.reopen => l10n.groupBatchConfirmReopen(
          count,
          groupName,
        ),
      }),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(switch (action) {
            GroupBatchAction.pause => l10n.pause,
            GroupBatchAction.close => l10n.close,
            GroupBatchAction.reopen => l10n.reopen,
          }),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  String message;
  var failed = false;
  try {
    final result = await service.updateGroupStatus(
      groupId,
      action.target,
      message: change?.message,
      resumeAt: change?.resumeAt,
    );
    if (result.isEmpty) {
      message = l10n.groupBatchEmpty;
    } else if (result.isComplete) {
      message = l10n.groupBatchDone(result.updated);
    } else if (result.isPartial) {
      message = l10n.groupBatchPartial(result.updated, result.total);
      failed = true;
    } else {
      message = l10n.genericActionError;
      failed = true;
    }
  } on Exception catch (e) {
    message = describeActionError(e).message(l10n);
    failed = true;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: failed ? QioColors.error : null,
      ),
    );
}
