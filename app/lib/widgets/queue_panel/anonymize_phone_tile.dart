import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_card.dart';

class AnonymizePhoneTile extends StatefulWidget {
  const AnonymizePhoneTile({
    super.key,
    required this.queueId,
    required this.value,
    this.queues,
  });

  final String queueId;
  final bool value;
  final QueueService? queues;

  @override
  State<AnonymizePhoneTile> createState() => _AnonymizePhoneTileState();
}

class _AnonymizePhoneTileState extends State<AnonymizePhoneTile> {
  bool _busy = false;

  Future<void> _toggle(bool next) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await (widget.queues ?? QueueService.instance).updateAnonymizePhone(
        widget.queueId,
        next,
      );
    } on Exception {
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
    final l10n = AppLocalizations.of(context);
    return QioCard(
      child: Row(
        children: [
          Icon(Icons.phonelink_erase_outlined, color: context.qio.primaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.anonymizePhoneTitle,
                  style: context.qioText.bodyMedium.copyWith(
                    color: context.qio.textPrimary,
                  ),
                ),
                Text(l10n.anonymizePhoneHint, style: context.qioText.caption),
              ],
            ),
          ),
          Switch(value: widget.value, onChanged: _busy ? null : _toggle),
        ],
      ),
    );
  }
}
