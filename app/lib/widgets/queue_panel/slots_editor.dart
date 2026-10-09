import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/queue_schedule.dart';
import '../../models/queue_slot.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_card.dart';
import 'queue_schedule_tile.dart';

String slotsErrorText(SlotsError error, AppLocalizations l10n) {
  switch (error) {
    case SlotsError.required:
      return l10n.slotsRequired;
    case SlotsError.duplicate:
      return l10n.slotsDuplicate;
    case SlotsError.tooMany:
      return l10n.slotsTooMany(maxQueueSlots);
    case SlotsError.invalid:
      return l10n.slotsInvalid;
  }
}

class SlotsEditor extends StatelessWidget {
  const SlotsEditor({
    super.key,
    required this.mode,
    required this.slots,
    required this.onChanged,
    this.schedule,
    this.error,
    this.enabled = true,
    this.initialSlots = const [],
    this.showModeSelector = true,
  });

  final bool showModeSelector;
  final QueueMode mode;
  final List<QueueSlot> slots;
  final void Function(QueueMode mode, List<QueueSlot> slots) onChanged;
  final QueueSchedule? schedule;
  final SlotsError? error;
  final bool enabled;
  final List<QueueSlot> initialSlots;

  Future<void> _add(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    onChanged(mode, [
      ...slots,
      QueueSlot(id: newSlotId(), start: formatHm(picked), capacity: 1),
    ]);
  }

  Future<void> _editTime(BuildContext context, QueueSlot slot) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: parseHm(slot.start),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    _replace(slot.copyWith(start: formatHm(picked)));
  }

  void _replace(QueueSlot next) {
    onChanged(mode, [for (final s in slots) s.id == next.id ? next : s]);
  }

  void _remove(QueueSlot slot) {
    onChanged(mode, [
      for (final s in slots)
        if (s.id != slot.id) s,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sorted = sortedSlots(slots);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showModeSelector) ...[
          Text(
            l10n.queueModeLabel,
            style: context.qioText.label.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.qio.gray700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.modeQueue),
                avatar: const Icon(Icons.people_alt_outlined, size: 18),
                selected: mode == QueueMode.queue,
                onSelected: enabled
                    ? (_) => onChanged(QueueMode.queue, slots)
                    : null,
              ),
              ChoiceChip(
                label: Text(l10n.modeSchedule),
                avatar: const Icon(Icons.event_available_outlined, size: 18),
                selected: mode == QueueMode.schedule,
                onSelected: enabled
                    ? (_) => onChanged(QueueMode.schedule, slots)
                    : null,
              ),
            ],
          ),
        ],
        if (mode == QueueMode.schedule) ...[
          if (showModeSelector) const SizedBox(height: 16),
          Text(
            l10n.slotsEditorTitle,
            style: context.qioText.label.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.qio.gray700,
            ),
          ),
          const SizedBox(height: 4),
          Text(l10n.slotsEditorHint, style: context.qioText.caption),
          const SizedBox(height: 8),
          for (final slot in sorted)
            _SlotRow(
              key: ValueKey(slot.id),
              slot: slot,
              enabled: enabled,
              outside: slotOutsideWindows(slot.start, schedule),
              onTime: () => _editTime(context, slot),
              onCapacity: (n) => _replace(slot.copyWith(capacity: n)),
              onRemove: () => _remove(slot),
            ),
          if (slotTimesChanged(initialSlots, slots))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.slotTimeChangeWarning,
                style: context.qioText.caption.copyWith(
                  color: QioColors.warning,
                ),
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                slotsErrorText(error!, l10n),
                style: context.qioText.caption.copyWith(color: QioColors.error),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('slots-add'),
              onPressed: enabled && slots.length < maxQueueSlots
                  ? () => _add(context)
                  : null,
              icon: const Icon(Icons.add),
              label: Text(l10n.addSlot),
            ),
          ),
        ],
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    super.key,
    required this.slot,
    required this.enabled,
    required this.outside,
    required this.onTime,
    required this.onCapacity,
    required this.onRemove,
  });

  final QueueSlot slot;
  final bool enabled;
  final bool outside;
  final VoidCallback onTime;
  final void Function(int) onCapacity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: enabled ? onTime : null,
                icon: const Icon(Icons.access_time, size: 18),
                label: Text(
                  slot.start,
                  style: context.qioText.bodyMedium.copyWith(
                    color: context.qio.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: '-',
                onPressed: enabled && slot.capacity > 1
                    ? () => onCapacity(slot.capacity - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                l10n.slotCapacity(slot.capacity),
                style: context.qioText.caption,
              ),
              IconButton(
                tooltip: '+',
                onPressed: enabled && slot.capacity < maxSlotCapacity
                    ? () => onCapacity(slot.capacity + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
              IconButton(
                tooltip: l10n.removeSlot,
                onPressed: enabled ? onRemove : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          if (outside)
            Text(
              l10n.slotsOutsideSchedule(slot.start),
              style: context.qioText.caption.copyWith(color: QioColors.warning),
            ),
        ],
      ),
    );
  }
}

class QueueSlotsTile extends StatelessWidget {
  const QueueSlotsTile({
    super.key,
    required this.queueId,
    required this.mode,
    required this.slots,
    this.schedule,
    this.queues,
  });

  final String queueId;
  final QueueMode mode;
  final List<QueueSlot> slots;
  final QueueSchedule? schedule;
  final QueueService? queues;

  Future<void> _edit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<(QueueMode, List<QueueSlot>)>(
      context: context,
      builder: (_) =>
          _SlotsDialog(mode: mode, slots: slots, schedule: schedule),
    );
    if (result == null || !context.mounted) return;
    try {
      await (queues ?? QueueService.instance).updateModeAndSlots(
        queueId,
        result.$1,
        result.$2,
      );
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.genericActionError),
          backgroundColor: QioColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return QioCard(
      onTap: () => _edit(context),
      child: Row(
        children: [
          Icon(Icons.event_available_outlined, color: context.qio.primaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.queueModeLabel,
                  style: context.qioText.bodyMedium.copyWith(
                    color: context.qio.textPrimary,
                  ),
                ),
                Text(
                  mode == QueueMode.schedule
                      ? '${l10n.modeSchedule} · '
                            '${l10n.slotsTileSummary(slots.length)}'
                      : l10n.modeQueue,
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

class _SlotsDialog extends StatefulWidget {
  const _SlotsDialog({
    required this.mode,
    required this.slots,
    required this.schedule,
  });

  final QueueMode mode;
  final List<QueueSlot> slots;
  final QueueSchedule? schedule;

  @override
  State<_SlotsDialog> createState() => _SlotsDialogState();
}

class _SlotsDialogState extends State<_SlotsDialog> {
  late QueueMode _mode = widget.mode;
  late List<QueueSlot> _slots = [...widget.slots];
  SlotsError? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.queueModeLabel),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: SlotsEditor(
            mode: _mode,
            slots: _slots,
            schedule: widget.schedule,
            initialSlots: widget.slots,
            error: _error,
            onChanged: (mode, slots) => setState(() {
              _mode = mode;
              _slots = slots;
              _error = null;
            }),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            final error = validateSlots(_mode, _slots);
            if (error != null) {
              setState(() => _error = error);
              return;
            }
            Navigator.of(context).pop((_mode, _slots));
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
