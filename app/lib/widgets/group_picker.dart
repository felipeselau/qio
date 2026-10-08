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
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: initial);
  final formKey = GlobalKey<FormState>();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: QioInput(
          label: l10n.groupName,
          controller: controller,
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
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.of(ctx).pop(controller.text.trim());
          },
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

const _newGroupValue = '\u0000new';

class GroupPicker extends StatelessWidget {
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

  Future<void> _create(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final name = await showGroupNameDialog(context, title: l10n.groupNew);
    if (name == null || !context.mounted) return;
    try {
      final group = await (groups ?? GroupService.instance).createGroup(name);
      onChanged(group.id);
    } on Exception catch (e) {
      if (context.mounted) showGroupError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<QueueGroup>>(
      stream: (groups ?? GroupService.instance).watchGroups(),
      builder: (context, snap) {
        final groups = snap.data ?? const <QueueGroup>[];
        final selected = groups.any((g) => g.id == value) ? value : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.groupLabel, style: context.qioText.label),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              key: ValueKey(selected),
              initialValue: selected,
              isExpanded: true,
              onChanged: enabled
                  ? (v) {
                      if (v == _newGroupValue) {
                        _create(context);
                      } else {
                        onChanged(v);
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
