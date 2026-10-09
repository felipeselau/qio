import 'dart:convert';

import '../models/expiry_config.dart';
import '../models/queue_schedule.dart';
import '../models/queue_slot.dart';
import '../services/brand_palette.dart';

const createQueueDraftVersion = 1;

class CreateQueueDraft {
  const CreateQueueDraft({
    this.name = '',
    this.description = '',
    this.groupId,
    this.avgServiceMin = '',
    this.maxWaiting = '',
    this.mode = QueueMode.queue,
    this.slots = const [],
    this.brandColor,
    this.schedule,
    this.expiry,
  });

  final String name;
  final String description;
  final String? groupId;
  final String avgServiceMin;
  final String maxWaiting;
  final QueueMode mode;
  final List<QueueSlot> slots;
  final String? brandColor;
  final QueueSchedule? schedule;
  final ExpiryConfig? expiry;

  CreateQueueDraft copyWith({
    String? name,
    String? description,
    String? groupId,
    bool clearGroupId = false,
    String? avgServiceMin,
    String? maxWaiting,
    QueueMode? mode,
    List<QueueSlot>? slots,
    String? brandColor,
    bool clearBrandColor = false,
    QueueSchedule? schedule,
    bool clearSchedule = false,
    ExpiryConfig? expiry,
    bool clearExpiry = false,
  }) {
    return CreateQueueDraft(
      name: name ?? this.name,
      description: description ?? this.description,
      groupId: clearGroupId ? null : groupId ?? this.groupId,
      avgServiceMin: avgServiceMin ?? this.avgServiceMin,
      maxWaiting: maxWaiting ?? this.maxWaiting,
      mode: mode ?? this.mode,
      slots: slots ?? this.slots,
      brandColor: clearBrandColor ? null : brandColor ?? this.brandColor,
      schedule: clearSchedule ? null : schedule ?? this.schedule,
      expiry: clearExpiry ? null : expiry ?? this.expiry,
    );
  }

  CreateQueueDraft trimmed() {
    final group = groupId?.trim() ?? '';
    return CreateQueueDraft(
      name: name.trim(),
      description: description.trim(),
      groupId: group.isEmpty ? null : group,
      avgServiceMin: avgServiceMin.trim(),
      maxWaiting: maxWaiting.trim(),
      mode: mode,
      slots: slots,
      brandColor: brandColor,
      schedule: schedule,
      expiry: expiry,
    );
  }

  Map<String, Object?> toJson() => {
    'version': createQueueDraftVersion,
    'name': name,
    'description': description,
    'groupId': groupId,
    'avgServiceMin': avgServiceMin,
    'maxWaiting': maxWaiting,
    'mode': mode.value,
    'slots': [for (final s in slots) s.toMap()],
    'brandColor': brandColor,
    'schedule': schedule?.toMap(),
    'expiry': expiry?.toMap(),
  };

  static CreateQueueDraft? fromJson(Object? raw, {Set<String>? validGroupIds}) {
    if (raw is! Map) return null;
    final version = raw['version'];
    if (version is! int || version < 1 || version > createQueueDraftVersion) {
      return null;
    }
    String text(Object? v) => v is String ? v : '';

    final mode = QueueModeX.fromValue(raw['mode'] as String?);

    var slots = <QueueSlot>[];
    final rawSlots = raw['slots'];
    if (rawSlots is List) {
      slots = [for (final item in rawSlots) ?QueueSlot.fromMap(item)];
      if (validateSlots(QueueMode.schedule, slots) != null) slots = [];
    }

    var schedule = QueueSchedule.fromMap(raw['schedule']);
    if (schedule != null && validateSchedule(schedule) != null) {
      schedule = null;
    }

    final rawGroup = raw['groupId'];
    final group = rawGroup is String && rawGroup.trim().isNotEmpty
        ? rawGroup.trim()
        : null;
    final groupOk =
        group != null &&
        (validGroupIds == null || validGroupIds.contains(group));

    final rawColor = raw['brandColor'];
    final color = brandPalette.any((c) => c.hex == rawColor)
        ? rawColor as String
        : null;

    return CreateQueueDraft(
      name: text(raw['name']),
      description: text(raw['description']),
      groupId: groupOk ? group : null,
      avgServiceMin: text(raw['avgServiceMin']),
      maxWaiting: text(raw['maxWaiting']),
      mode: mode,
      slots: slots,
      brandColor: color,
      schedule: schedule,
      expiry: ExpiryConfig.fromMap(raw['expiry']),
    );
  }

  String get _key => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      other is CreateQueueDraft && other._key == _key;

  @override
  int get hashCode => _key.hashCode;
}
