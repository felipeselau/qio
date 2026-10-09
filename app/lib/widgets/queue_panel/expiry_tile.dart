import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/expiry_config.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_colors.dart';
import '../qio_card.dart';
import '../queue_form/expiry_form.dart';

class ExpiryTile extends StatefulWidget {
  const ExpiryTile({
    super.key,
    required this.queueId,
    required this.config,
    this.queues,
  });

  final String queueId;
  final ExpiryConfig? config;
  final QueueService? queues;

  @override
  State<ExpiryTile> createState() => _ExpiryTileState();
}

class _ExpiryTileState extends State<ExpiryTile> {
  bool _busy = false;

  ExpiryConfig get _current => widget.config ?? const ExpiryConfig();

  Future<void> _save(ExpiryConfig next) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await (widget.queues ?? QueueService.instance).updateExpiry(
        widget.queueId,
        next,
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.genericActionError),
          backgroundColor: QioColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return QioCard(
      child: ExpiryForm(value: _current, enabled: !_busy, onChanged: _save),
    );
  }
}
