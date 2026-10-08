import 'package:flutter/material.dart';

import '../../models/queue.dart';
import '../../models/queue_slot.dart';
import '../../services/group_service.dart';
import '../../services/queue_service.dart';
import 'alerts_tile.dart';
import 'duplicate_queue_tile.dart';
import 'edit_queue_tile.dart';
import 'operators_tile.dart';
import 'queue_brand_tile.dart';
import 'queue_group_tile.dart';
import 'queue_limit_tile.dart';
import 'queue_qr_card.dart';
import 'queue_schedule_tile.dart';
import 'slots_editor.dart';

const kPanelWideBreakpoint = 900.0;
const kPanelCompactBarBreakpoint = 420.0;

bool isPanelWide(double width) => width >= kPanelWideBreakpoint;

bool isPanelCompactBar(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kPanelCompactBarBreakpoint ||
    MediaQuery.textScalerOf(context).scale(10) > 12;

class QueueSettingsSections extends StatelessWidget {
  const QueueSettingsSections({
    super.key,
    required this.queueId,
    required this.queueName,
    required this.isOwner,
    required this.queue,
    required this.joinUrl,
    this.qrKey,
    this.queues,
    this.groups,
  });

  final String queueId;
  final String queueName;
  final bool isOwner;
  final Queue? queue;
  final String joinUrl;
  final GlobalKey? qrKey;
  final QueueService? queues;
  final GroupService? groups;

  @override
  Widget build(BuildContext context) {
    final current = queue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        QueueQrCard(
          key: qrKey,
          queueName: current?.name ?? queueName,
          joinUrl: joinUrl,
        ),
        if (isOwner) ...[
          OperatorsTile(queueId: queueId),
          QueueLimitTile(
            queueId: queueId,
            maxWaiting: current?.maxWaiting ?? 0,
          ),
          QueueSlotsTile(
            queueId: queueId,
            mode: current?.mode ?? QueueMode.queue,
            slots: current?.slots ?? const [],
            schedule: current?.schedule,
          ),
          QueueGroupTile(
            queueId: queueId,
            groupId: current?.groupId,
            groups: groups,
          ),
          QueueScheduleTile(queueId: queueId, schedule: current?.schedule),
          AlertsTile(queueId: queueId, config: current?.alerts),
          QueueBrandTile(
            queueId: queueId,
            queueName: current?.name ?? queueName,
            brandColor: current?.brandColor,
            logoUrl: current?.logoUrl,
          ),
          if (current != null) ...[
            EditQueueTile(queue: current, queues: queues),
            DuplicateQueueTile(queue: current, queues: queues, groups: groups),
          ],
        ],
      ],
    );
  }
}
