import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/queue_goals.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_card.dart';
import '../qio_input.dart';

typedef GoalsDialogResult = ({QueueGoals? goals});

class GoalsTile extends StatelessWidget {
  const GoalsTile({
    super.key,
    required this.queueId,
    required this.goals,
    this.queues,
  });

  final String queueId;
  final QueueGoals? goals;
  final QueueService? queues;

  Future<void> _edit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<GoalsDialogResult>(
      context: context,
      builder: (_) => GoalsDialog(initial: goals),
    );
    if (result == null) return;
    try {
      await (queues ?? QueueService.instance).updateGoals(
        queueId,
        result.goals,
      );
    } on Exception {
      messenger.showSnackBar(
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
    final g = goals;
    final parts = [
      if (g?.maxWaitMin != null) l10n.goalsValueWait(g!.maxWaitMin!),
      if (g?.maxServiceMin != null) l10n.goalsValueService(g!.maxServiceMin!),
      if (g != null && g.hasGoal) l10n.goalsValueTarget(g.effectiveTargetPct),
    ];
    return QioCard(
      key: const ValueKey('goals-tile'),
      onTap: () => _edit(context),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, color: context.qio.primaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.goalsTitle,
                  style: context.qioText.bodyMedium.copyWith(
                    color: context.qio.textPrimary,
                  ),
                ),
                Text(
                  parts.isEmpty ? l10n.goalsNone : parts.join(' · '),
                  key: const ValueKey('goals-summary'),
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

class GoalsDialog extends StatefulWidget {
  const GoalsDialog({super.key, required this.initial});

  final QueueGoals? initial;

  @override
  State<GoalsDialog> createState() => _GoalsDialogState();
}

class _GoalsDialogState extends State<GoalsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _wait = TextEditingController(
    text: widget.initial?.maxWaitMin?.toString() ?? '',
  );
  late final _service = TextEditingController(
    text: widget.initial?.maxServiceMin?.toString() ?? '',
  );
  late final _target = TextEditingController(
    text: widget.initial?.targetPct?.toString() ?? '',
  );
  bool _noGoal = false;

  @override
  void dispose() {
    _wait.dispose();
    _service.dispose();
    _target.dispose();
    super.dispose();
  }

  String? _validate(
    String? v,
    (int, int) range,
    String Function(int, int) message,
  ) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return null;
    final n = int.tryParse(text);
    if (n == null || n < range.$1 || n > range.$2) {
      return message(range.$1, range.$2);
    }
    return null;
  }

  int? _read(TextEditingController c) => int.tryParse(c.text.trim());

  void _save() {
    final hasGoal =
        _wait.text.trim().isNotEmpty || _service.text.trim().isNotEmpty;
    setState(() => _noGoal = !hasGoal);
    if (!_formKey.currentState!.validate() || !hasGoal) return;
    final goals = QueueGoals(
      maxWaitMin: _read(_wait),
      maxServiceMin: _read(_service),
      targetPct: _read(_target),
    );
    if (goals.validate() != null) return;
    Navigator.of(context).pop<GoalsDialogResult>((goals: goals));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.goalsTitle),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.goalsDialogHint, style: context.qioText.caption),
            const SizedBox(height: 12),
            QioInput(
              key: const ValueKey('goals-wait'),
              label: l10n.goalsWaitLabel,
              controller: _wait,
              keyboardType: TextInputType.number,
              autofocus: true,
              validator: (v) =>
                  _validate(v, QueueGoals.waitRange, l10n.goalsErrRange),
            ),
            const SizedBox(height: 12),
            QioInput(
              key: const ValueKey('goals-service'),
              label: l10n.goalsServiceLabel,
              controller: _service,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  _validate(v, QueueGoals.serviceRange, l10n.goalsErrRange),
            ),
            const SizedBox(height: 12),
            QioInput(
              key: const ValueKey('goals-target'),
              label: l10n.goalsTargetLabel,
              hint: l10n.goalsTargetHint(QueueGoals.defaultTargetPct),
              controller: _target,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  _validate(v, QueueGoals.targetRange, l10n.goalsErrTarget),
            ),
            if (_noGoal) ...[
              const SizedBox(height: 8),
              Text(
                l10n.goalsErrNone,
                key: const ValueKey('goals-error-none'),
                style: context.qioText.caption.copyWith(color: QioColors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('goals-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        if (widget.initial != null)
          TextButton(
            key: const ValueKey('goals-remove'),
            onPressed: () =>
                Navigator.of(context).pop<GoalsDialogResult>((goals: null)),
            child: Text(l10n.goalsRemove),
          ),
        TextButton(
          key: const ValueKey('goals-save'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
