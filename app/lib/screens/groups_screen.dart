import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/queue_group.dart';
import '../services/group_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/group_picker.dart';
import '../widgets/qio_card.dart';
import '../widgets/qio_empty_state.dart';
import '../widgets/qio_responsive_body.dart';
import '../widgets/qio_skeleton.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final name = await showGroupNameDialog(context, title: l10n.groupNew);
    if (name == null || !context.mounted) return;
    try {
      await GroupService.instance.createGroup(name);
    } on Exception catch (e) {
      if (context.mounted) showGroupError(context, e);
    }
  }

  Future<void> _rename(BuildContext context, QueueGroup group) async {
    final l10n = AppLocalizations.of(context);
    final name = await showGroupNameDialog(
      context,
      title: l10n.groupRename,
      initial: group.name,
    );
    if (name == null || name == group.name || !context.mounted) return;
    try {
      await GroupService.instance.renameGroup(group.id, name);
    } on Exception catch (e) {
      if (context.mounted) showGroupError(context, e);
    }
  }

  Future<void> _delete(BuildContext context, QueueGroup group) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.groupDelete),
        content: Text(l10n.groupDeleteConfirm(group.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: QioColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await GroupService.instance.deleteGroup(group.id);
    } on Exception catch (e) {
      if (context.mounted) showGroupError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: QioColors.gray100,
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        title: Text(
          l10n.groups,
          style: QioTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: QioColors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.groupNew,
        onPressed: () => _create(context),
        child: const Icon(Icons.add),
      ),
      body: QioResponsiveBody(
        child: StreamBuilder<List<QueueGroup>>(
          stream: GroupService.instance.watchGroups(),
          builder: (context, snap) {
            if (snap.hasError) {
              final err = snap.error;
              return QioErrorState(
                message:
                    err is FirebaseException && err.code == 'permission-denied'
                    ? l10n.groupPermissionDenied
                    : null,
              );
            }
            if (!snap.hasData) return const QioSkeletonList(count: 3);
            final groups = snap.data!;
            if (groups.isEmpty) {
              return QioEmptyState(
                icon: Icons.folder_outlined,
                title: l10n.groups,
                message: l10n.groupsEmpty,
                actionLabel: l10n.groupNew,
                onAction: () => _create(context),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final g in groups)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: QioCard(
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            color: QioColors.primaryText,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              g.name,
                              style: QioTextStyles.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.groupRename,
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _rename(context, g),
                          ),
                          IconButton(
                            tooltip: l10n.groupDelete,
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: QioColors.error,
                            ),
                            onPressed: () => _delete(context, g),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
