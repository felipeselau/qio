import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/alerts_config.dart';
import '../models/queue.dart';
import '../services/action_errors.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import 'queue_form/alerts_form.dart';

AlertsConfig initialGroupAlerts(Iterable<Queue> queues) {
  for (final q in queues) {
    final a = q.alerts;
    if (a != null) return a;
  }
  return const AlertsConfig();
}

class _GroupAlertsDialog extends StatefulWidget {
  const _GroupAlertsDialog({required this.groupName, required this.initial});

  final String groupName;
  final AlertsConfig initial;

  @override
  State<_GroupAlertsDialog> createState() => _GroupAlertsDialogState();
}

class _GroupAlertsDialogState extends State<_GroupAlertsDialog> {
  late AlertsConfig _config = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.groupAlertsDialogTitle(widget.groupName)),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.groupAlertsDialogHint, style: context.qioText.caption),
          const SizedBox(height: 12),
          AlertsForm(
            value: _config,
            onChanged: (c) => setState(() => _config = c),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const ValueKey('group-alerts-continue'),
          onPressed: _config.validate() == null
              ? () => Navigator.of(context).pop(_config)
              : null,
          child: Text(l10n.groupAlertsContinue),
        ),
      ],
    );
  }
}

Future<void> runGroupApplyAlerts(
  BuildContext context, {
  required QueueService service,
  required String groupId,
  required String groupName,
  required List<Queue> queues,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final config = await showDialog<AlertsConfig>(
    context: context,
    builder: (_) => _GroupAlertsDialog(
      groupName: groupName,
      initial: initialGroupAlerts(queues),
    ),
  );
  if (config == null || !context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(l10n.groupAlertsConfirm(queues.length, groupName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const ValueKey('group-alerts-apply'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.groupAlertsApply),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  String message;
  var failed = false;
  try {
    final result = await service.applyGroupAlerts(groupId, config);
    if (result.isEmpty) {
      message = l10n.groupBatchEmpty;
    } else if (result.isComplete) {
      message = l10n.groupAlertsDone(result.updated);
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
