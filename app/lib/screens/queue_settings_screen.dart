import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/queue.dart';
import '../services/group_service.dart';
import '../services/queue_service.dart';
import '../theme/qio_palette.dart';
import '../widgets/qio_responsive_body.dart';
import '../widgets/queue_panel/queue_settings_sections.dart';

class QueueSettingsScreen extends StatelessWidget {
  const QueueSettingsScreen({
    super.key,
    required this.queueId,
    required this.queueName,
    required this.isOwner,
    this.queues,
    this.groups,
  });

  final String queueId;
  final String queueName;
  final bool isOwner;
  final QueueService? queues;
  final GroupService? groups;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = queues ?? QueueService.instance;
    return Scaffold(
      backgroundColor: context.qio.gray100,
      appBar: AppBar(
        backgroundColor: context.qio.surface,
        title: Text(l10n.queueSettingsTitle),
        centerTitle: true,
      ),
      body: QioResponsiveBody(
        maxWidth: 600,
        child: StreamBuilder<Queue>(
          stream: service.watchQueue(queueId),
          builder: (context, snap) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              QueueSettingsSections(
                queueId: queueId,
                queueName: queueName,
                isOwner: isOwner,
                queue: snap.data,
                joinUrl: service.queueJoinUrl(queueId),
                queues: queues,
                groups: groups,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
