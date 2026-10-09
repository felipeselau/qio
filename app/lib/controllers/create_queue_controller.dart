import 'package:flutter/foundation.dart';

import '../models/expiry_config.dart';
import '../models/queue_info.dart';
import '../models/queue_schedule.dart';
import '../models/queue_slot.dart';
import 'create_queue_draft.dart';

enum CreateQueueStep { name, mode, capacity, appearance, schedule, review }

enum CreateQueueField {
  name,
  description,
  avgServiceMin,
  maxWaiting,
  slots,
  schedule,
}

class CreateQueueArgs {
  const CreateQueueArgs({
    required this.name,
    required this.description,
    required this.avgServiceMin,
    required this.maxWaiting,
    required this.groupId,
    required this.mode,
    required this.slots,
    required this.schedule,
    required this.brandColor,
    required this.expiry,
  });

  final String name;
  final String? description;
  final int avgServiceMin;
  final int maxWaiting;
  final String? groupId;
  final QueueMode mode;
  final List<QueueSlot> slots;
  final QueueSchedule? schedule;
  final String? brandColor;
  final ExpiryConfig? expiry;
}

class CreateQueueController extends ChangeNotifier {
  CreateQueueController({
    CreateQueueDraft? initial,
    CreateQueueDraft? draft,
    CreateQueueStep step = CreateQueueStep.name,
  }) : _initial = initial ?? const CreateQueueDraft(),
       _draft = draft ?? initial ?? const CreateQueueDraft(),
       _step = step,
       _maxReached = step.index;

  static const optionalSteps = {
    CreateQueueStep.capacity,
    CreateQueueStep.appearance,
    CreateQueueStep.schedule,
  };

  final CreateQueueDraft _initial;
  CreateQueueDraft _draft;
  CreateQueueStep _step;
  int _maxReached;
  bool _returnToReview = false;

  CreateQueueDraft get draft => _draft;
  CreateQueueDraft get initial => _initial;
  CreateQueueStep get step => _step;
  int get stepIndex => _step.index;
  int get totalSteps => CreateQueueStep.values.length;
  bool get isFirst => _step.index == 0;
  bool get isReview => _step == CreateQueueStep.review;
  bool get returningToReview => _returnToReview;
  bool isOptional(CreateQueueStep step) => optionalSteps.contains(step);

  bool get isDirty => _draft.trimmed() != _initial.trimmed();

  Map<CreateQueueField, Enum> errorsFor(CreateQueueStep step) {
    final d = _draft;
    final errors = <CreateQueueField, Enum>{};
    switch (step) {
      case CreateQueueStep.name:
        final name = QueueInfo.validateName(d.name);
        if (name != null) errors[CreateQueueField.name] = name;
        final desc = QueueInfo.validateDescription(d.description);
        if (desc != null) errors[CreateQueueField.description] = desc;
      case CreateQueueStep.mode:
        final slots = validateSlots(d.mode, d.slots);
        if (slots != null) errors[CreateQueueField.slots] = slots;
      case CreateQueueStep.capacity:
        final avg = _avgError(d.avgServiceMin);
        if (avg != null) errors[CreateQueueField.avgServiceMin] = avg;
        final max = validateMaxWaitingText(d.maxWaiting);
        if (max != null) errors[CreateQueueField.maxWaiting] = max;
      case CreateQueueStep.appearance:
        break;
      case CreateQueueStep.schedule:
        final schedule = validateSchedule(d.schedule);
        if (schedule != null) errors[CreateQueueField.schedule] = schedule;
      case CreateQueueStep.review:
        for (final s in CreateQueueStep.values) {
          if (s == CreateQueueStep.review) continue;
          errors.addAll(errorsFor(s));
        }
    }
    return errors;
  }

  Enum? errorFor(CreateQueueStep step) {
    final errors = errorsFor(step);
    return errors.isEmpty ? null : errors.values.first;
  }

  bool canContinue(CreateQueueStep step) => errorsFor(step).isEmpty;

  CreateQueueStep? get firstInvalidStep {
    for (final s in CreateQueueStep.values) {
      if (s == CreateQueueStep.review) continue;
      if (!canContinue(s)) return s;
    }
    return null;
  }

  void update(CreateQueueDraft Function(CreateQueueDraft draft) change) {
    final next = change(_draft);
    if (next == _draft) return;
    _draft = next;
    notifyListeners();
  }

  bool next() {
    if (isReview || !canContinue(_step)) return false;
    if (_returnToReview) {
      _returnToReview = false;
      _go(CreateQueueStep.review);
    } else {
      _go(CreateQueueStep.values[_step.index + 1]);
    }
    return true;
  }

  bool skip() {
    if (!isOptional(_step)) return false;
    _draft = _resetFor(_step);
    return next();
  }

  bool back() {
    if (isFirst) return false;
    if (_returnToReview) {
      _returnToReview = false;
      _go(CreateQueueStep.review);
      return true;
    }
    _go(CreateQueueStep.values[_step.index - 1]);
    return true;
  }

  bool jumpTo(CreateQueueStep target) {
    if (target == _step || target.index > _maxReached) return false;
    for (var i = _step.index; i < target.index; i++) {
      if (!canContinue(CreateQueueStep.values[i])) return false;
    }
    _returnToReview =
        _step == CreateQueueStep.review && target != CreateQueueStep.review;
    _go(target);
    return true;
  }

  CreateQueueArgs toCreateArgs() {
    final errors = errorsFor(CreateQueueStep.review);
    if (errors.isNotEmpty) throw FormatException(errors.values.first.name);
    final d = _draft.trimmed();
    final schedule = d.schedule;
    return CreateQueueArgs(
      name: d.name,
      description: QueueInfo.normalizeDescription(d.description),
      avgServiceMin:
          QueueInfo.parseAvgServiceMin(d.avgServiceMin) ?? defaultAvgServiceMin,
      maxWaiting: int.tryParse(d.maxWaiting) ?? 0,
      groupId: d.groupId,
      mode: d.mode,
      slots: d.mode == QueueMode.schedule ? sortedSlots(d.slots) : const [],
      schedule: schedule != null && schedule.enabled ? schedule : null,
      brandColor: d.brandColor,
      expiry: d.expiry,
    );
  }

  Map<String, Object?> toJson() => {..._draft.toJson(), 'step': _step.name};

  static CreateQueueController? fromJson(
    Object? raw, {
    Set<String>? validGroupIds,
  }) {
    final draft = CreateQueueDraft.fromJson(raw, validGroupIds: validGroupIds);
    if (draft == null) return null;
    final name = (raw as Map)['step'];
    var step = CreateQueueStep.values.firstWhere(
      (s) => s.name == name,
      orElse: () => CreateQueueStep.name,
    );
    final probe = CreateQueueController(draft: draft);
    final bad = probe.firstInvalidStep;
    if (bad != null && bad.index < step.index) step = bad;
    return CreateQueueController(draft: draft, step: step);
  }

  void _go(CreateQueueStep target) {
    _step = target;
    if (target.index > _maxReached) _maxReached = target.index;
    notifyListeners();
  }

  CreateQueueDraft _resetFor(CreateQueueStep step) {
    switch (step) {
      case CreateQueueStep.capacity:
        return _draft.copyWith(avgServiceMin: '', maxWaiting: '');
      case CreateQueueStep.appearance:
        return _draft.copyWith(clearBrandColor: true);
      case CreateQueueStep.schedule:
        return _draft.copyWith(clearSchedule: true, clearExpiry: true);
      default:
        return _draft;
    }
  }

  static QueueInfoError? _avgError(String raw) {
    if (raw.trim().isEmpty) return null;
    return QueueInfo.validateAvgServiceMin(QueueInfo.parseAvgServiceMin(raw));
  }
}
