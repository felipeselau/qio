import 'dart:math';

import 'queue_schedule.dart';

const int maxQueueSlots = 24;
const int maxSlotCapacity = 50;
final RegExp _slotTimeRe = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
const Duration _spOffset = Duration(hours: 3);

enum QueueMode { queue, schedule }

extension QueueModeX on QueueMode {
  String get value => this == QueueMode.schedule ? 'schedule' : 'queue';

  static QueueMode fromValue(String? v) =>
      v == 'schedule' ? QueueMode.schedule : QueueMode.queue;
}

enum SlotsError { required, duplicate, tooMany, invalid }

class QueueSlot {
  const QueueSlot({
    required this.id,
    required this.start,
    required this.capacity,
  });

  final String id;
  final String start;
  final int capacity;

  QueueSlot copyWith({String? start, int? capacity}) => QueueSlot(
    id: id,
    start: start ?? this.start,
    capacity: capacity ?? this.capacity,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'start': start,
    'capacity': capacity,
  };

  Map<String, dynamic> toMirror() => {'start': start, 'capacity': capacity};

  static QueueSlot? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final start = raw['start'];
    final capacity = raw['capacity'];
    if (id is! String || id.isEmpty) return null;
    if (start is! String || !isValidSlotTime(start)) return null;
    if (capacity is! num) return null;
    return QueueSlot(id: id, start: start, capacity: capacity.toInt());
  }

  static List<QueueSlot> listFromRaw(Object? raw) {
    if (raw is! List) return const [];
    return sortedSlots([for (final item in raw) ?QueueSlot.fromMap(item)]);
  }
}

bool isValidSlotTime(String value) => _slotTimeRe.hasMatch(value);

List<QueueSlot> sortedSlots(Iterable<QueueSlot> slots) =>
    slots.toList()..sort((a, b) => a.start.compareTo(b.start));

String newSlotId([Random? random]) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final r = random ?? Random.secure();
  return List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
}

SlotsError? validateSlots(QueueMode mode, List<QueueSlot> slots) {
  if (mode == QueueMode.queue) return null;
  if (slots.isEmpty) return SlotsError.required;
  if (slots.length > maxQueueSlots) return SlotsError.tooMany;
  final seen = <String>{};
  for (final s in slots) {
    if (!isValidSlotTime(s.start) ||
        s.capacity < 1 ||
        s.capacity > maxSlotCapacity ||
        s.id.isEmpty) {
      return SlotsError.invalid;
    }
    if (!seen.add(s.start)) return SlotsError.duplicate;
  }
  return null;
}

String formatSlotStart(int millis) {
  final sp = DateTime.fromMillisecondsSinceEpoch(
    millis,
    isUtc: true,
  ).subtract(_spOffset);
  return '${sp.hour.toString().padLeft(2, '0')}:'
      '${sp.minute.toString().padLeft(2, '0')}';
}

int _minutes(String hm) {
  final parts = hm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

bool slotOutsideWindows(String start, QueueSchedule? schedule) {
  if (schedule == null || !schedule.enabled || schedule.windows.isEmpty) {
    return false;
  }
  if (!isValidSlotTime(start)) return false;
  final t = _minutes(start);
  for (final w in schedule.windows) {
    if (!isValidSlotTime(w.open) || !isValidSlotTime(w.close)) continue;
    final open = _minutes(w.open);
    final close = _minutes(w.close);
    final inside = close > open
        ? t >= open && t < close
        : t >= open || t < close;
    if (inside) return false;
  }
  return true;
}

Map<String, dynamic>? slotsMirror(List<QueueSlot> slots) {
  if (slots.isEmpty) return null;
  return {for (final s in slots) s.id: s.toMirror()};
}
