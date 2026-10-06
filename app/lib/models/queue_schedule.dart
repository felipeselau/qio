class ScheduleWindow {
  const ScheduleWindow({
    required this.days,
    required this.open,
    required this.close,
  });

  final List<int> days;
  final String open;
  final String close;

  Map<String, dynamic> toMap() => {'days': days, 'open': open, 'close': close};

  factory ScheduleWindow.fromMap(Map<dynamic, dynamic> map) => ScheduleWindow(
    days: [
      for (final d in (map['days'] as List<dynamic>? ?? const []))
        if (d is num) d.toInt(),
    ],
    open: map['open'] as String? ?? '08:00',
    close: map['close'] as String? ?? '18:00',
  );
}

class QueueSchedule {
  const QueueSchedule({
    required this.enabled,
    this.timezone = defaultTimezone,
    this.windows = const [],
  });

  static const defaultTimezone = 'America/Sao_Paulo';

  final bool enabled;
  final String timezone;
  final List<ScheduleWindow> windows;

  static QueueSchedule? fromMap(Object? raw) {
    if (raw is! Map) return null;
    return QueueSchedule(
      enabled: raw['enabled'] == true,
      timezone: raw['timezone'] as String? ?? defaultTimezone,
      windows: [
        for (final w in (raw['windows'] as List<dynamic>? ?? const []))
          if (w is Map) ScheduleWindow.fromMap(w),
      ],
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'timezone': timezone,
    'windows': [for (final w in windows) w.toMap()],
  };
}

String? validateWindow(List<int> days, String open, String close) {
  if (days.isEmpty) return 'days';
  if (open == close) return 'time';
  return null;
}
