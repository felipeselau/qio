import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_schedule.dart';
import 'package:qio_app/widgets/queue_panel/queue_schedule_tile.dart';

void main() {
  test('compactDays groups consecutive days', () {
    expect(compactDays([1, 2, 3, 4, 5]), [(1, 5)]);
    expect(compactDays([5, 1, 2, 7]), [(1, 2), (5, 5), (7, 7)]);
    expect(compactDays([3, 3, 3]), [(3, 3)]);
    expect(compactDays([0, 8, 2]), [(2, 2)]);
    expect(compactDays([]), isEmpty);
  });

  test('parseHm and formatHm round trip', () {
    expect(formatHm(parseHm('08:05')), '08:05');
    expect(formatHm(const TimeOfDay(hour: 18, minute: 0)), '18:00');
    expect(parseHm('x').hour, 8);
  });

  test('validateWindow requires days and distinct times', () {
    expect(validateWindow([], '08:00', '18:00'), 'days');
    expect(validateWindow([1], '08:00', '08:00'), 'time');
    expect(validateWindow([1], '22:00', '02:00'), isNull);
  });

  test('schedule serializes and parses back', () {
    const s = QueueSchedule(
      enabled: true,
      windows: [
        ScheduleWindow(days: [1, 2, 3], open: '09:00', close: '17:30'),
      ],
    );
    final parsed = QueueSchedule.fromMap(s.toMap())!;
    expect(parsed.enabled, isTrue);
    expect(parsed.timezone, QueueSchedule.defaultTimezone);
    expect(parsed.windows.single.days, [1, 2, 3]);
    expect(parsed.windows.single.close, '17:30');
    expect(QueueSchedule.fromMap(null), isNull);
  });
}
