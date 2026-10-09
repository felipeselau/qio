import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/queue_schedule.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_card.dart';
import '../queue_form/schedule_form.dart';
import '../../theme/qio_palette.dart';

export '../queue_form/schedule_form.dart'
    show compactDays, dayLabel, daysSummary, formatHm, parseHm;

class QueueScheduleTile extends StatelessWidget {
  const QueueScheduleTile({
    super.key,
    required this.queueId,
    required this.schedule,
  });

  final String queueId;
  final QueueSchedule? schedule;

  Future<void> _edit(BuildContext context) async {
    final result = await showDialog<_ScheduleResult>(
      context: context,
      builder: (_) => _ScheduleDialog(initial: schedule),
    );
    if (result == null || !context.mounted) return;
    try {
      await QueueService.instance.updateSchedule(queueId, result.schedule);
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).genericActionError),
          backgroundColor: QioColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final s = schedule;
    final w = s != null && s.enabled && s.windows.isNotEmpty
        ? s.windows.first
        : null;
    return QioCard(
      onTap: () => _edit(context),
      child: Row(
        children: [
          Icon(Icons.schedule, color: context.qio.primaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.scheduleTitle,
                  style: context.qioText.bodyMedium.copyWith(
                    color: context.qio.textPrimary,
                  ),
                ),
                Text(
                  w == null
                      ? l10n.scheduleOff
                      : l10n.scheduleHours(
                          daysSummary(w.days, locale),
                          w.open,
                          w.close,
                        ),
                  style: context.qioText.caption,
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, size: 18, color: context.qio.gray500),
        ],
      ),
    );
  }
}

class _ScheduleResult {
  const _ScheduleResult(this.schedule);

  final QueueSchedule? schedule;
}

class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog({required this.initial});

  final QueueSchedule? initial;

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  late ScheduleFormValue _value = ScheduleFormValue.fromSchedule(
    widget.initial,
  );
  String? _error;

  void _change(ScheduleFormValue next) {
    setState(() {
      if (!setEquals(next.days, _value.days)) _error = null;
      _value = next;
    });
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final problem = _value.problem;
    if (problem != null) {
      setState(
        () => _error = problem == 'days'
            ? l10n.scheduleInvalidDays
            : l10n.scheduleInvalidTime,
      );
      return;
    }
    Navigator.of(context).pop(_ScheduleResult(_value.toSchedule()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.scheduleTitle),
      content: SingleChildScrollView(
        child: ScheduleForm(
          value: _value,
          onChanged: _change,
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
