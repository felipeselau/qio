import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/queue_schedule.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';

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

class ScheduleFormValue {
  const ScheduleFormValue({
    this.enabled = false,
    this.days = const {1, 2, 3, 4, 5},
    this.open = const TimeOfDay(hour: 8, minute: 0),
    this.close = const TimeOfDay(hour: 18, minute: 0),
  });

  factory ScheduleFormValue.fromSchedule(QueueSchedule? schedule) {
    final window = schedule?.windows.firstOrNull;
    return ScheduleFormValue(
      enabled: schedule?.enabled ?? false,
      days: {
        ...(window?.days ?? const [1, 2, 3, 4, 5]),
      },
      open: parseHm(window?.open ?? '08:00'),
      close: parseHm(window?.close ?? '18:00'),
    );
  }

  final bool enabled;
  final Set<int> days;
  final TimeOfDay open;
  final TimeOfDay close;

  ScheduleFormValue copyWith({
    bool? enabled,
    Set<int>? days,
    TimeOfDay? open,
    TimeOfDay? close,
  }) {
    return ScheduleFormValue(
      enabled: enabled ?? this.enabled,
      days: days ?? this.days,
      open: open ?? this.open,
      close: close ?? this.close,
    );
  }

  String? get problem {
    if (!enabled) return null;
    return validateWindow(days.toList(), formatHm(open), formatHm(close));
  }

  QueueSchedule? toSchedule() {
    if (!enabled) return null;
    return QueueSchedule(
      enabled: true,
      windows: [
        ScheduleWindow(
          days: days.toList()..sort(),
          open: formatHm(open),
          close: formatHm(close),
        ),
      ],
    );
  }
}

class ScheduleForm extends StatelessWidget {
  const ScheduleForm({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final ScheduleFormValue value;
  final ValueChanged<ScheduleFormValue> onChanged;
  final String? errorText;

  Future<void> _pick(BuildContext context, bool open) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: open ? value.open : value.close,
    );
    if (picked == null || !context.mounted) return;
    onChanged(
      open ? value.copyWith(open: picked) : value.copyWith(close: picked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.scheduleEnabled),
          value: value.enabled,
          onChanged: (v) => onChanged(value.copyWith(enabled: v)),
        ),
        if (value.enabled) ...[
          Text(l10n.scheduleDays, style: context.qioText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(dayLabel(d, locale)),
                  selected: value.days.contains(d),
                  onSelected: (v) {
                    final days = {...value.days};
                    v ? days.add(d) : days.remove(d);
                    onChanged(value.copyWith(days: days));
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(context, true),
                  child: Text('${l10n.scheduleOpens} ${formatHm(value.open)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(context, false),
                  child: Text(
                    '${l10n.scheduleCloses} ${formatHm(value.close)}',
                  ),
                ),
              ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              errorText!,
              style: context.qioText.caption.copyWith(
                color: context.qio.statusClosedText,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(l10n.scheduleNote, style: context.qioText.caption),
        ],
      ],
    );
  }
}
