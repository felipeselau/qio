import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_entry.dart';
import 'package:qio_app/models/queue_schedule.dart';
import 'package:qio_app/models/queue_slot.dart';

QueueSlot slot(String id, String start, [int capacity = 2]) =>
    QueueSlot(id: id, start: start, capacity: capacity);

void main() {
  group('QueueSlot', () {
    test('serializes and parses back', () {
      final s = slot('a1', '09:30', 3);
      final parsed = QueueSlot.fromMap(s.toMap())!;
      expect(parsed.id, 'a1');
      expect(parsed.start, '09:30');
      expect(parsed.capacity, 3);
      expect(s.toMirror(), {'start': '09:30', 'capacity': 3});
    });

    test('fromMap rejects malformed data', () {
      expect(QueueSlot.fromMap(null), isNull);
      expect(
        QueueSlot.fromMap({'id': '', 'start': '09:00', 'capacity': 1}),
        isNull,
      );
      expect(
        QueueSlot.fromMap({'id': 'a', 'start': '9:00', 'capacity': 1}),
        isNull,
      );
      expect(
        QueueSlot.fromMap({'id': 'a', 'start': '24:00', 'capacity': 1}),
        isNull,
      );
      expect(QueueSlot.fromMap({'id': 'a', 'start': '09:00'}), isNull);
    });

    test('listFromRaw sorts by time and drops invalid', () {
      final list = QueueSlot.listFromRaw([
        slot('b', '10:00').toMap(),
        slot('a', '08:00').toMap(),
        {'id': 'x'},
      ]);
      expect(list.map((s) => s.id), ['a', 'b']);
      expect(QueueSlot.listFromRaw(null), isEmpty);
    });

    test('newSlotId has the expected shape and is unique enough', () {
      final ids = {for (var i = 0; i < 50; i++) newSlotId()};
      expect(ids.length, 50);
      expect(ids.every((id) => RegExp(r'^[a-z0-9]{8}$').hasMatch(id)), isTrue);
    });
  });

  group('validateSlots', () {
    test('queue mode never fails', () {
      expect(validateSlots(QueueMode.queue, []), isNull);
    });

    test('schedule mode needs slots', () {
      expect(validateSlots(QueueMode.schedule, []), SlotsError.required);
      expect(validateSlots(QueueMode.schedule, [slot('a', '09:00')]), isNull);
    });

    test('rejects duplicates, invalid values and more than 24', () {
      expect(
        validateSlots(QueueMode.schedule, [
          slot('a', '09:00'),
          slot('b', '09:00'),
        ]),
        SlotsError.duplicate,
      );
      expect(
        validateSlots(QueueMode.schedule, [slot('a', '09:00', 0)]),
        SlotsError.invalid,
      );
      expect(
        validateSlots(QueueMode.schedule, [slot('a', '09:00', 51)]),
        SlotsError.invalid,
      );
      expect(
        validateSlots(QueueMode.schedule, [slot('a', '9:00')]),
        SlotsError.invalid,
      );
      final many = [
        for (var i = 0; i < 25; i++)
          slot('s$i', '${(i % 24).toString().padLeft(2, '0')}:00'),
      ];
      expect(validateSlots(QueueMode.schedule, many), SlotsError.tooMany);
      expect(validateSlots(QueueMode.schedule, many.take(24).toList()), isNull);
    });
  });

  group('helpers', () {
    test('formatSlotStart renders Sao Paulo time', () {
      final ms = DateTime.utc(2026, 10, 7, 12, 30).millisecondsSinceEpoch;
      expect(formatSlotStart(ms), '09:30');
      final late = DateTime.utc(2026, 10, 8, 1, 5).millisecondsSinceEpoch;
      expect(formatSlotStart(late), '22:05');
    });

    test('slotOutsideWindows warns only with an enabled schedule', () {
      const s = QueueSchedule(
        enabled: true,
        windows: [
          ScheduleWindow(days: [1], open: '08:00', close: '12:00'),
        ],
      );
      expect(slotOutsideWindows('09:00', s), isFalse);
      expect(slotOutsideWindows('12:00', s), isTrue);
      expect(slotOutsideWindows('07:59', s), isTrue);
      expect(slotOutsideWindows('07:59', null), isFalse);
      const night = QueueSchedule(
        enabled: true,
        windows: [
          ScheduleWindow(days: [1], open: '22:00', close: '02:00'),
        ],
      );
      expect(slotOutsideWindows('23:30', night), isFalse);
      expect(slotOutsideWindows('01:00', night), isFalse);
      expect(slotOutsideWindows('12:00', night), isTrue);
    });

    test('slotsMirror maps by id', () {
      expect(slotsMirror([]), isNull);
      expect(slotsMirror([slot('a', '09:00', 4)]), {
        'a': {'start': '09:00', 'capacity': 4},
      });
    });
  });

  group('Queue and QueueEntry', () {
    test('Queue defaults to queue mode without slots', () {
      final q = Queue.fromDoc('q1', {'ownerId': 'o', 'name': 'x'});
      expect(q.mode, QueueMode.queue);
      expect(q.slots, isEmpty);
      expect(q.isScheduled, isFalse);
    });

    test('Queue parses mode and slots', () {
      final q = Queue.fromDoc('q1', {
        'ownerId': 'o',
        'name': 'x',
        'mode': 'schedule',
        'slots': [slot('a', '09:00').toMap()],
      });
      expect(q.isScheduled, isTrue);
      expect(q.slots.single.start, '09:00');
    });

    test('QueueEntry parses slotId and slotStart', () {
      final e = QueueEntry.fromSnapshot('e1', {
        'ticket': 1,
        'name': 'Ana',
        'uid': 'u',
        'status': 'waiting',
        'joinedAt': 1,
        'slotId': 'a',
        'slotStart': 1790000000000,
      });
      expect(e.slotId, 'a');
      expect(e.slotStart!.millisecondsSinceEpoch, 1790000000000);
      final plain = QueueEntry.fromSnapshot('e2', {'ticket': 2, 'uid': 'u'});
      expect(plain.slotStart, isNull);
    });
  });
}
