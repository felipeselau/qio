import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/queue_group.dart';
import '../theme/qio_text_styles.dart';

class MoveTarget {
  const MoveTarget.group(this.groupId) : createNew = false;
  const MoveTarget.none() : groupId = null, createNew = false;
  const MoveTarget.create() : groupId = null, createNew = true;

  final String? groupId;
  final bool createNew;
}

Future<MoveTarget?> showMoveToGroupSheet(
  BuildContext context, {
  required List<QueueGroup> groups,
  required int count,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<MoveTarget>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.moveToGroupTitle(count),
                style: ctx.qioText.heading3,
              ),
            ),
            ListTile(
              key: const ValueKey('move-target-none'),
              minTileHeight: 48,
              leading: const Icon(Icons.folder_off_outlined),
              title: Text(l10n.groupNone),
              onTap: () => Navigator.of(ctx).pop(const MoveTarget.none()),
            ),
            for (final g in groups)
              ListTile(
                key: ValueKey('move-target-${g.id}'),
                minTileHeight: 48,
                leading: Icon(Icons.folder_outlined, color: g.color),
                title: Text(g.name),
                onTap: () => Navigator.of(ctx).pop(MoveTarget.group(g.id)),
              ),
            ListTile(
              key: const ValueKey('move-target-new'),
              minTileHeight: 48,
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(l10n.groupNew),
              onTap: () => Navigator.of(ctx).pop(const MoveTarget.create()),
            ),
          ],
        ),
      ),
    ),
  );
}
