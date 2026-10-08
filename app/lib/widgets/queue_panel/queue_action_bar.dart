import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/queue.dart';
import '../../models/queue_entry.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_colors.dart';
import '../../widgets/qio_button.dart';

class QueueActionBar extends StatelessWidget {
  const QueueActionBar({
    super.key,
    required this.queueId,
    required this.isOwner,
    required this.callNextKey,
    required this.actionLoading,
    required this.finishLoading,
    required this.deleteLoading,
    required this.isMine,
    required this.onCallNext,
    required this.onServed,
    required this.onNoShow,
    required this.onDelete,
    this.queues,
  });

  final String queueId;
  final bool isOwner;
  final GlobalKey callNextKey;
  final bool actionLoading;
  final bool finishLoading;
  final bool deleteLoading;
  final bool Function(QueueEntry) isMine;
  final VoidCallback onCallNext;
  final void Function(QueueEntry) onServed;
  final void Function(QueueEntry) onNoShow;
  final VoidCallback onDelete;
  final QueueService? queues;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = queues ?? QueueService.instance;
    return Container(
      decoration: BoxDecoration(
        color: QioColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<Queue>(
            stream: service.watchQueue(queueId),
            builder: (context, qSnap) {
              final status = qSnap.data?.status ?? QueueStatus.open;
              if (status == QueueStatus.closed) {
                if (!isOwner) return const SizedBox.shrink();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QioButton(
                      label: l10n.deleteQueue,
                      variant: QioButtonVariant.danger,
                      icon: Icons.delete_outline,
                      isFullWidth: true,
                      onPressed: deleteLoading ? null : onDelete,
                      isLoading: deleteLoading,
                    ),
                  ],
                );
              }
              return StreamBuilder<List<QueueEntry>>(
                stream: service.watchEntries(queueId),
                builder: (context, snap) {
                  final entries = snap.data ?? [];
                  final mine = entries
                      .where((e) => e.status == EntryStatus.called && isMine(e))
                      .toList();
                  final current = mine.isNotEmpty ? mine.first : null;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QioButton(
                        key: callNextKey,
                        label: l10n.callNext,
                        onPressed: (actionLoading || current != null)
                            ? null
                            : onCallNext,
                        isLoading: actionLoading,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: QioButton(
                              label: l10n.served,
                              variant: QioButtonVariant.successSoft,
                              isFullWidth: true,
                              fontSize: 14,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              onPressed: current == null || finishLoading
                                  ? null
                                  : () => onServed(current),
                              isLoading: finishLoading,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QioButton(
                              label: l10n.noShow,
                              variant: QioButtonVariant.dangerSoft,
                              isFullWidth: true,
                              fontSize: 14,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              onPressed: current == null || finishLoading
                                  ? null
                                  : () => onNoShow(current),
                              isLoading: finishLoading,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
