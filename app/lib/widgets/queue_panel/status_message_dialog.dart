import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/queue.dart';
import '../../theme/qio_text_styles.dart';

class StatusChange {
  const StatusChange({this.message, this.resumeAt});

  final String? message;
  final DateTime? resumeAt;
}

DateTime resumeTimeToday(TimeOfDay time, DateTime now) {
  var at = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
  return at;
}

Future<StatusChange?> showStatusMessageDialog(
  BuildContext context,
  QueueStatus target,
) {
  return showDialog<StatusChange>(
    context: context,
    builder: (_) => _StatusMessageDialog(target: target),
  );
}

class _StatusMessageDialog extends StatefulWidget {
  const _StatusMessageDialog({required this.target});

  final QueueStatus target;

  @override
  State<_StatusMessageDialog> createState() => _StatusMessageDialogState();
}

class _StatusMessageDialogState extends State<_StatusMessageDialog> {
  final _controller = TextEditingController();
  TimeOfDay? _resume;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _resume ??
          TimeOfDay.fromDateTime(
            DateTime.now().add(const Duration(minutes: 15)),
          ),
    );
    if (picked != null && mounted) setState(() => _resume = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pausing = widget.target == QueueStatus.paused;
    final suggestions = pausing
        ? [l10n.statusSuggestionBack10, l10n.statusSuggestionBreak]
        : [l10n.statusSuggestionClosedToday];
    return AlertDialog(
      title: Text(pausing ? l10n.pauseQueueTitle : l10n.closeQueueTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              maxLength: 120,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.statusMessageLabel),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final s in suggestions)
                  ActionChip(
                    label: Text(s),
                    onPressed: () => setState(() => _controller.text = s),
                  ),
              ],
            ),
            if (pausing) ...[
              const SizedBox(height: 12),
              Text(l10n.resumeAtLabel, style: context.qioText.label),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      _resume == null
                          ? l10n.resumeAtNone
                          : _resume!.format(context),
                    ),
                  ),
                  if (_resume != null)
                    IconButton(
                      tooltip: l10n.clear,
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _resume = null),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            StatusChange(
              message: _controller.text.trim().isEmpty
                  ? null
                  : _controller.text.trim(),
              resumeAt: _resume == null
                  ? null
                  : resumeTimeToday(_resume!, DateTime.now()),
            ),
          ),
          child: Text(pausing ? l10n.pause : l10n.close),
        ),
      ],
    );
  }
}
