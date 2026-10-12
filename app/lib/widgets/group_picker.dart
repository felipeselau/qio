import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/queue_group.dart';
import '../services/group_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import 'qio_input.dart';

String groupErrorMessage(AppLocalizations l10n, Object error) {
  if (error is GroupLimitReachedException) {
    return l10n.groupLimitReached(QueueGroup.maxPerOwner);
  }
  if (error is GroupPermissionDeniedException) {
    return l10n.groupPermissionDenied;
  }
  return l10n.genericActionError;
}

void showGroupError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(groupErrorMessage(AppLocalizations.of(context), error)),
      backgroundColor: QioColors.error,
    ),
  );
}

Future<String?> showGroupNameDialog(
  BuildContext context, {
  String initial = '',
  required String title,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _GroupNameDialog(title: title, initial: initial),
  );
}

class _GroupNameDialog extends StatefulWidget {
  const _GroupNameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_GroupNameDialog> createState() => _GroupNameDialogState();
}

class _GroupNameDialogState extends State<_GroupNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: QioInput(
          label: l10n.groupName,
          controller: _controller,
          autofocus: true,
          validator: (v) {
            final text = v?.trim() ?? '';
            if (text.isEmpty || text.length > QueueGroup.maxNameLength) {
              return l10n.groupName;
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

const _newGroupValue = '\u0000new';

class GroupPicker extends StatefulWidget {
  const GroupPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.groups,
  });

  final GroupService? groups;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  State<GroupPicker> createState() => _GroupPickerState();
}

class _GroupPickerState extends State<GroupPicker> {
  late Stream<List<QueueGroup>> _stream = _open();

  Stream<List<QueueGroup>> _open() =>
      (widget.groups ?? GroupService.instance).watchGroups();

  @override
  void didUpdateWidget(GroupPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groups != widget.groups) _stream = _open();
  }

  Future<void> _create(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final name = await showGroupNameDialog(context, title: l10n.groupNew);
    if (name == null || !context.mounted) return;
    try {
      final group = await (widget.groups ?? GroupService.instance).createGroup(
        name,
      );
      widget.onChanged(group.id);
    } on Exception catch (e) {
      if (context.mounted) showGroupError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<QueueGroup>>(
      stream: _stream,
      builder: (context, snap) {
        final groups = snap.data ?? const <QueueGroup>[];
        final selected = groups.any((g) => g.id == widget.value)
            ? widget.value
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.groupLabel, style: context.qioText.label),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              key: ValueKey(selected),
              initialValue: selected,
              isExpanded: true,
              onChanged: widget.enabled
                  ? (v) {
                      if (v == _newGroupValue) {
                        _create(context);
                      } else {
                        widget.onChanged(v);
                      }
                    }
                  : null,
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.groupNone),
                ),
                for (final g in groups)
                  DropdownMenuItem<String?>(
                    value: g.id,
                    child: Text(g.name, overflow: TextOverflow.ellipsis),
                  ),
                DropdownMenuItem<String?>(
                  value: _newGroupValue,
                  child: Text(l10n.groupNew),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
