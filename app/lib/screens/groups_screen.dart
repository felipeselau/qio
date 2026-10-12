import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/queue.dart';
import '../models/queue_group.dart';
import '../services/group_service.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/group_picker.dart';
import '../widgets/qio_card.dart';
import '../widgets/qio_empty_state.dart';
import '../widgets/qio_responsive_body.dart';
import '../widgets/qio_skeleton.dart';
import '../theme/qio_palette.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key, this.groups, this.queues});

  final GroupService? groups;
  final QueueService? queues;

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  GroupService get _groups => widget.groups ?? GroupService.instance;
  late final Stream<List<QueueGroup>> _stream = _groups.watchGroups();
  late final Stream<List<Queue>>? _queuesStream = _watchQueues();

  Stream<List<Queue>>? _watchQueues() {
    try {
      return (widget.queues ?? QueueService.instance).watchOwnerQueues();
    } catch (_) {
      return null;
    }
  }

  Future<void> _create(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final name = await showGroupNameDialog(context, title: l10n.groupNew);
    if (name == null || !context.mounted) return;
    try {
      await _groups.createGroup(name);
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
      await _groups.renameGroup(group.id, name);
    } on Exception catch (e) {
      if (context.mounted) showGroupError(context, e);
    }
  }

  Future<void> _delete(
    BuildContext context,
    QueueGroup group,
    int? count,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.groupDelete),
        content: Text(
          count == null || count == 0
              ? l10n.groupDeleteConfirm(group.name)
              : l10n.groupDeleteConfirmCount(group.name, count),
        ),
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
      await _groups.deleteGroup(group.id);
    } on Exception catch (e) {
      if (context.mounted) showGroupError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.qio.gray100,
      appBar: AppBar(
        backgroundColor: context.qio.surface,
        title: Text(
          l10n.groups,
          style: context.qioText.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: context.qio.textPrimary,
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
          stream: _stream,
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
            return StreamBuilder<List<Queue>>(
              stream: _queuesStream,
              builder: (context, queuesSnap) {
                final owned = queuesSnap.hasError ? null : queuesSnap.data;
                Map<String, int>? counts;
                if (owned != null) {
                  counts = {};
                  for (final q in owned) {
                    final id = resolveGroupId(q, groups);
                    if (id != null) counts[id] = (counts[id] ?? 0) + 1;
                  }
                }
                return _list(context, groups, counts);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    List<QueueGroup> groups,
    Map<String, int>? counts,
  ) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final g in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: QioCard(
              child: Row(
                children: [
                  Icon(Icons.folder_outlined, color: context.qio.primaryText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.name,
                          style: context.qioText.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (counts != null)
                          Text(
                            l10n.groupQueueCount(counts[g.id] ?? 0),
                            style: context.qioText.caption.copyWith(
                              fontSize: 12,
                              color: context.qio.gray700,
                            ),
                          ),
                      ],
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
                    onPressed: () => _delete(context, g, counts?[g.id]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
