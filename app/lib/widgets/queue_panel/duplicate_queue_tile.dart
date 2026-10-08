import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/queue.dart';
import '../../models/queue_info.dart';
import '../../screens/queue_panel_screen.dart';
import '../../services/group_service.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_card.dart';
import '../queue_info_fields.dart';

class DuplicateQueueTile extends StatefulWidget {
  const DuplicateQueueTile({
    super.key,
    required this.queue,
    this.queues,
    this.groups,
    this.panelBuilder,
  });

  final Queue queue;
  final QueueService? queues;
  final GroupService? groups;
  @visibleForTesting
  final Widget Function(Queue copy)? panelBuilder;

  @override
  State<DuplicateQueueTile> createState() => _DuplicateQueueTileState();
}

class _DuplicateQueueTileState extends State<DuplicateQueueTile> {
  bool _busy = false;

  Future<void> _duplicate() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final service = widget.queues ?? QueueService.instance;
    setState(() => _busy = true);
    try {
      final copy = await service.duplicateQueue(
        widget.queue.id,
        name: duplicateQueueName(
          widget.queue.name,
          l10n.duplicateQueueCopyWord,
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.queueDuplicated)));
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              widget.panelBuilder?.call(copy) ??
              QueuePanelScreen(
                queueId: copy.id,
                queueName: copy.name,
                queues: widget.queues,
                groups: widget.groups,
              ),
        ),
      );
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(queueErrorMessage(e, l10n)),
          backgroundColor: QioColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return QioCard(
      onTap: _busy ? null : _duplicate,
      child: Row(
        children: [
          Icon(Icons.copy_all_outlined, color: context.qio.primaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.duplicateQueue,
                  style: context.qioText.bodyMedium.copyWith(
                    color: context.qio.textPrimary,
                  ),
                ),
                Text(l10n.duplicateQueueHint, style: context.qioText.caption),
              ],
            ),
          ),
          if (_busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.chevron_right, size: 18, color: context.qio.gray500),
        ],
      ),
    );
  }
}
