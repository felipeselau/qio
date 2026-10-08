import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/queue.dart';
import '../services/group_service.dart';
import '../services/queue_service.dart';
import '../theme/qio_palette.dart';
import '../widgets/qio_responsive_body.dart';
import '../widgets/queue_panel/queue_settings_sections.dart';

enum QueueSettingsExit { queueGone }

class QueueSettingsScreen extends StatefulWidget {
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
  State<QueueSettingsScreen> createState() => _QueueSettingsScreenState();
}

class _QueueSettingsScreenState extends State<QueueSettingsScreen> {
  QueueService get _queues => widget.queues ?? QueueService.instance;
  late final Stream<Queue> _queueStream = _queues.watchQueue(widget.queueId);
  StreamSubscription<bool>? _existsSub;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _existsSub = _queues.watchQueueExists(widget.queueId).listen((exists) {
      if (!exists) _queueGone();
    }, onError: (_) => _queueGone());
  }

  @override
  void dispose() {
    _existsSub?.cancel();
    super.dispose();
  }

  void _queueGone() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).pop(QueueSettingsExit.queueGone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.qio.gray100,
      appBar: AppBar(
        backgroundColor: context.qio.surface,
        title: Text(
          widget.isOwner ? l10n.queueSettingsTitle : l10n.queueQrTitle,
        ),
        centerTitle: true,
      ),
      body: QioResponsiveBody(
        maxWidth: 600,
        child: StreamBuilder<Queue>(
          stream: _queueStream,
          builder: (context, snap) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              QueueSettingsSections(
                queueId: widget.queueId,
                queueName: widget.queueName,
                isOwner: widget.isOwner,
                queue: snap.data,
                joinUrl: _queues.queueJoinUrl(widget.queueId),
                queues: widget.queues,
                groups: widget.groups,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
