import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/queue_schedule.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_card.dart';

List<(int, int)> compactDays(List<int> days) {
  final sorted = {...days}.where((d) => d >= 1 && d <= 7).toList()..sort();
  final ranges = <(int, int)>[];
  for (final d in sorted) {
    if (ranges.isNotEmpty && ranges.last.$2 == d - 1) {
      ranges.last = (ranges.last.$1, d);
    } else {
      ranges.add((d, d));
    }
  }
  return ranges;
}

String dayLabel(int day, String locale) =>
    DateFormat.E(locale).format(DateTime(2024, 1, day));

String daysSummary(List<int> days, String locale) {
  return compactDays(days)
      .map(
        (r) => r.$1 == r.$2
            ? dayLabel(r.$1, locale)
            : r.$2 == r.$1 + 1
            ? '${dayLabel(r.$1, locale)}, ${dayLabel(r.$2, locale)}'
            : '${dayLabel(r.$1, locale)}–${dayLabel(r.$2, locale)}',
      )
      .join(', ');
}

TimeOfDay parseHm(String value) {
  final parts = value.split(':');
  return TimeOfDay(
    hour: int.tryParse(parts.first) ?? 8,
    minute: int.tryParse(parts.last) ?? 0,
  );
}

String formatHm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
          Icon(Icons.schedule, color: QioColors.primaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.scheduleTitle,
                  style: QioTextStyles.bodyMedium.copyWith(
                    color: QioColors.textPrimary,
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
                  style: QioTextStyles.caption,
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, size: 18, color: QioColors.gray500),
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
  late bool _enabled = widget.initial?.enabled ?? false;
  late final Set<int> _days = {
    ...(widget.initial?.windows.firstOrNull?.days ?? const [1, 2, 3, 4, 5]),
  };
  late TimeOfDay _open = parseHm(
    widget.initial?.windows.firstOrNull?.open ?? '08:00',
  );
  late TimeOfDay _close = parseHm(
    widget.initial?.windows.firstOrNull?.close ?? '18:00',
  );
  String? _error;

  Future<void> _pick(bool open) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: open ? _open : _close,
    );
    if (picked == null || !mounted) return;
    setState(() => open ? _open = picked : _close = picked);
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    if (!_enabled) {
      Navigator.of(context).pop(const _ScheduleResult(null));
      return;
    }
    final problem = validateWindow(
      _days.toList(),
      formatHm(_open),
      formatHm(_close),
    );
    if (problem != null) {
      setState(
        () => _error = problem == 'days'
            ? l10n.scheduleInvalidDays
            : l10n.scheduleInvalidTime,
      );
      return;
    }
    Navigator.of(context).pop(
      _ScheduleResult(
        QueueSchedule(
          enabled: true,
          windows: [
            ScheduleWindow(
              days: _days.toList()..sort(),
              open: formatHm(_open),
              close: formatHm(_close),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return AlertDialog(
      title: Text(l10n.scheduleTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.scheduleEnabled),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            if (_enabled) ...[
              Text(l10n.scheduleDays, style: QioTextStyles.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      label: Text(dayLabel(d, locale)),
                      selected: _days.contains(d),
                      onSelected: (v) => setState(() {
                        v ? _days.add(d) : _days.remove(d);
                        _error = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pick(true),
                      child: Text('${l10n.scheduleOpens} ${formatHm(_open)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pick(false),
                      child: Text('${l10n.scheduleCloses} ${formatHm(_close)}'),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: QioTextStyles.caption.copyWith(
                    color: QioColors.statusClosedText,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(l10n.scheduleNote, style: QioTextStyles.caption),
            ],
          ],
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
