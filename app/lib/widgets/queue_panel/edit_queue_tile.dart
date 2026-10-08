import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/queue.dart';
import '../../screens/edit_queue_screen.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_card.dart';

class EditQueueTile extends StatelessWidget {
  const EditQueueTile({super.key, required this.queue, this.queues});

  final Queue queue;
  final QueueService? queues;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return QioCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EditQueueScreen(queue: queue, queues: queues),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note_outlined, color: context.qio.primaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.editQueue,
                  style: context.qioText.bodyMedium.copyWith(
                    color: context.qio.textPrimary,
                  ),
                ),
                Text(l10n.editQueueHint, style: context.qioText.caption),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: context.qio.gray500),
        ],
      ),
    );
  }
}
