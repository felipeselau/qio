import '../models/queue_slot.dart';

bool mirrorNeedsRepair(
  Map<dynamic, dynamic>? owner,
  Map<dynamic, dynamic>? meta,
  String uid,
) {
  if (owner == null) return true;
  if (owner['ownerUid'] != uid) return true;
  if (meta == null) return true;
  return false;
}

Map<String, Object?>? mirrorModeSlotsPatch(
  Map<dynamic, dynamic>? meta,
  QueueMode mode,
  List<QueueSlot> slots,
) {
  if (meta == null) return null;
  final currentMode = QueueModeX.fromValue(meta['mode'] as String?);
  final expected = slotsMirror(slots) ?? const <String, dynamic>{};
  final raw = meta['slots'];
  final current = <String, Map<String, Object?>>{};
  if (raw is Map) {
    for (final e in raw.entries) {
      final v = e.value;
      if (v is Map) {
        current['${e.key}'] = {
          'start': v['start'],
          'capacity': (v['capacity'] as num?)?.toInt(),
        };
      }
    }
  }
  var same = currentMode == mode && current.length == expected.length;
  if (same) {
    for (final e in expected.entries) {
      final c = current[e.key];
      final v = e.value as Map<String, dynamic>;
      if (c == null ||
          c['start'] != v['start'] ||
          c['capacity'] != v['capacity']) {
        same = false;
        break;
      }
    }
  }
  if (same) return null;
  return {'mode': mode.value, 'slots': slotsMirror(slots)};
}
