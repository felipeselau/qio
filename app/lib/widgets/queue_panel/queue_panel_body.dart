import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/queue.dart';
import '../../models/queue_slot.dart';
import '../../models/queue_entry.dart';
import '../../services/group_service.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_text_styles.dart';
import '../../widgets/qio_card.dart';
import '../../widgets/qio_empty_state.dart';
import '../../widgets/qio_responsive_body.dart';
import '../../widgets/queue_panel/current_called_card.dart';
import '../../widgets/queue_panel/waiting_tile.dart';
import '../../widgets/queue_panel/queue_group_tile.dart';
import '../../widgets/queue_panel/queue_limit_tile.dart';
import '../../widgets/queue_panel/queue_brand_tile.dart';
import '../../widgets/queue_panel/queue_schedule_tile.dart';
import '../../widgets/queue_panel/alerts_tile.dart';
import '../../widgets/queue_panel/slots_editor.dart';
import '../../widgets/queue_panel/queue_qr_card.dart';
import '../../widgets/queue_panel/operators_tile.dart';
import 'animated_entry_list.dart';
import '../../theme/qio_palette.dart';

class QueuePanelBody extends StatelessWidget {
  const QueuePanelBody({
    super.key,
    required this.queueId,
    required this.queueName,
    required this.isOwner,
    required this.qrKey,
    required this.isMine,
    this.hiddenIds = const {},
    required this.onServed,
    required this.onNoShow,
    required this.onCall,
    required this.onMoveToEnd,
    required this.onRecall,
    this.queues,
    this.groups,
  });

  final String queueId;
  final String queueName;
  final bool isOwner;
  final GlobalKey qrKey;
  final bool Function(QueueEntry) isMine;
  final Set<String> hiddenIds;
  final void Function(QueueEntry) onServed;
  final void Function(QueueEntry) onNoShow;
  final void Function(QueueEntry) onCall;
  final void Function(QueueEntry) onMoveToEnd;
  final void Function(QueueEntry) onRecall;
  final QueueService? queues;
  final GroupService? groups;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = queues ?? QueueService.instance;
    final joinUrl = service.queueJoinUrl(queueId);
    return QioResponsiveBody(
      maxWidth: 1100,
      child: StreamBuilder<Queue>(
        stream: service.watchQueue(queueId),
        builder: (context, queueSnap) {
          final status = queueSnap.data?.status ?? QueueStatus.open;
          final maxWaiting = queueSnap.data?.maxWaiting ?? 0;
          final schedule = queueSnap.data?.schedule;
          final alerts = queueSnap.data?.alerts;
          if (status == QueueStatus.closed) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                QueueQrCard(key: qrKey, queueName: queueName, joinUrl: joinUrl),
                const SizedBox(height: 16),
                if (isOwner) ...[
                  OperatorsTile(queueId: queueId),
                  const SizedBox(height: 16),
                  QueueLimitTile(queueId: queueId, maxWaiting: maxWaiting),
                  const SizedBox(height: 16),
                  QueueSlotsTile(
                    queueId: queueId,
                    mode: queueSnap.data?.mode ?? QueueMode.queue,
                    slots: queueSnap.data?.slots ?? const [],
                    schedule: schedule,
                  ),
                  const SizedBox(height: 16),
                  QueueGroupTile(
                    queueId: queueId,
                    groupId: queueSnap.data?.groupId,
                    groups: groups,
                  ),
                  const SizedBox(height: 16),
                  QueueScheduleTile(queueId: queueId, schedule: schedule),
                  const SizedBox(height: 16),
                  AlertsTile(queueId: queueId, config: alerts),
                  const SizedBox(height: 16),
                  QueueBrandTile(
                    queueId: queueId,
                    queueName: queueName,
                    brandColor: queueSnap.data?.brandColor,
                    logoUrl: queueSnap.data?.logoUrl,
                  ),
                  const SizedBox(height: 16),
                ],
                QioCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(
                          l10n.queueClosedTitle,
                          style: context.qioText.heading3.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.qio.gray700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.noServiceInProgress,
                          style: context.qioText.caption,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    isOwner ? l10n.closedOwnerHint : l10n.closedOperatorHint,
                    style: context.qioText.body.copyWith(
                      fontSize: 14,
                      color: context.qio.gray400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }
          return StreamBuilder<List<QueueEntry>>(
            stream: service.watchEntries(queueId),
            builder: (context, snap) {
              final entries = (snap.data ?? [])
                  .where((e) => !hiddenIds.contains(e.id))
                  .toList();
              final waiting = entries
                  .where((e) => e.status == EntryStatus.waiting)
                  .toList();
              final called = entries
                  .where((e) => e.status == EntryStatus.called)
                  .toList();
              final mine = called.where(isMine).toList();
              final others = called.where((e) => !isMine(e)).toList();
              final current = mine.isNotEmpty ? mine.first : null;

              final qrSection = <Widget>[
                QueueQrCard(key: qrKey, queueName: queueName, joinUrl: joinUrl),
                const SizedBox(height: 16),
                if (isOwner) ...[
                  OperatorsTile(queueId: queueId),
                  const SizedBox(height: 16),
                  QueueLimitTile(queueId: queueId, maxWaiting: maxWaiting),
                  const SizedBox(height: 16),
                  QueueSlotsTile(
                    queueId: queueId,
                    mode: queueSnap.data?.mode ?? QueueMode.queue,
                    slots: queueSnap.data?.slots ?? const [],
                    schedule: schedule,
                  ),
                  const SizedBox(height: 16),
                  QueueGroupTile(
                    queueId: queueId,
                    groupId: queueSnap.data?.groupId,
                    groups: groups,
                  ),
                  const SizedBox(height: 16),
                  QueueScheduleTile(queueId: queueId, schedule: schedule),
                  const SizedBox(height: 16),
                  AlertsTile(queueId: queueId, config: alerts),
                  const SizedBox(height: 16),
                  QueueBrandTile(
                    queueId: queueId,
                    queueName: queueName,
                    brandColor: queueSnap.data?.brandColor,
                    logoUrl: queueSnap.data?.logoUrl,
                  ),
                  const SizedBox(height: 16),
                ],
              ];
              final queueSection = <Widget>[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.passthrough,
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  ),
                  child: CurrentCalledCard(
                    key: ValueKey(current?.id ?? 'none'),
                    entry: current,
                    queueId: queueId,
                    onRecall: current == null ? null : () => onRecall(current),
                  ),
                ),
                const SizedBox(height: 16),
                if (others.isNotEmpty) ...[
                  Text(
                    l10n.servingByOthers,
                    style: context.qioText.label.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.qio.gray700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...others.map(
                    (e) => WaitingTile(
                      entry: e,
                      trailing: isOwner
                          ? PopupMenuButton<EntryStatus>(
                              tooltip: l10n.finishService,
                              onSelected: (result) =>
                                  result == EntryStatus.served
                                  ? onServed(e)
                                  : onNoShow(e),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: EntryStatus.served,
                                  child: Text(l10n.served),
                                ),
                                PopupMenuItem(
                                  value: EntryStatus.noShow,
                                  child: Text(l10n.noShow),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (waiting.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.upNext,
                          style: context.qioText.label.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.qio.gray700,
                          ),
                        ),
                      ),
                      if (maxWaiting > 0)
                        Text(
                          l10n.waitingCounter(waiting.length, maxWaiting),
                          style: context.qioText.caption,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedEntryList(
                    entries: waiting,
                    itemBuilder: (context, e) => WaitingTile(
                      entry: e,
                      trailing: PopupMenuButton<String>(
                        tooltip: l10n.moreActions,
                        onSelected: (v) =>
                            v == 'call' ? onCall(e) : onMoveToEnd(e),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'call',
                            child: Text(l10n.callNow),
                          ),
                          PopupMenuItem(
                            value: 'move',
                            child: Text(l10n.moveToEnd),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else
                  QioCard(
                    child: QioEmptyState(
                      icon: Icons.hourglass_empty,
                      title: l10n.nobodyInQueue,
                      message: l10n.nobodyInQueueHint,
                      compact: true,
                    ),
                  ),
              ];
              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 400,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: qrSection,
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                            children: queueSection,
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [...qrSection, ...queueSection],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
