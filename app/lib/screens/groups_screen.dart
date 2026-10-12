import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../l10n/app_localizations.dart';
import '../models/queue.dart';
import '../models/queue_group.dart';
import '../services/group_service.dart';
import '../services/brand_palette.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/group_picker.dart';
import '../widgets/qio_card.dart';
import '../widgets/qio_empty_state.dart';
import '../widgets/qio_responsive_body.dart';
import '../widgets/qio_skeleton.dart';
import '../widgets/queue_form/brand_color_picker.dart';
import '../theme/qio_palette.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key, this.groups, this.queues});

  final GroupService? groups;
  final QueueService? queues;

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<String>? _optimistic;

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

  Future<void> _reorder(
    BuildContext context,
    List<QueueGroup> groups,
    int from,
    int target,
  ) async {
    if (target < 0 || target >= groups.length || target == from) return;
    final ids = [for (final g in groups) g.id];
    ids.insert(target, ids.removeAt(from));
    final moved = groups[from];
    setState(() => _optimistic = ids);
    SemanticsService.sendAnnouncement(
      View.of(context),
      AppLocalizations.of(context).groupMoved(moved.name, target + 1),
      Directionality.of(context),
    );
    try {
      await _groups.reorderGroups(ids);
    } on Exception catch (e) {
      if (context.mounted) showGroupError(context, e);
    } finally {
      if (mounted) setState(() => _optimistic = null);
    }
  }

  Future<void> _pickColor(BuildContext context, QueueGroup group) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<_ColorChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.groupColorOf(group.name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandColorPicker(
              value: group.colorHex,
              onChanged: (hex) => Navigator.of(ctx).pop(_ColorChoice(hex)),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('group-color-none'),
              onPressed: () => Navigator.of(ctx).pop(const _ColorChoice(null)),
              child: Text(l10n.groupColorNone),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (result == null || result.hex == group.colorHex || !context.mounted) {
      return;
    }
    try {
      await _groups.updateGroupColor(group.id, result.hex);
    } on Exception catch (e) {
      if (context.mounted) showGroupError(context, e);
    }
  }

  List<QueueGroup> _applyOptimistic(List<QueueGroup> groups) {
    final ids = _optimistic;
    if (ids == null) return groups;
    final byId = {for (final g in groups) g.id: g};
    if (ids.length != groups.length || ids.any((id) => !byId.containsKey(id))) {
      return groups;
    }
    return [for (final id in ids) byId[id]!];
  }

  Widget _list(
    BuildContext context,
    List<QueueGroup> source,
    Map<String, int>? counts,
  ) {
    final l10n = AppLocalizations.of(context);
    final groups = _applyOptimistic(source);
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      buildDefaultDragHandles: false,
      itemCount: groups.length,
      onReorderItem: (from, to) => _reorder(context, groups, from, to),
      itemBuilder: (context, index) {
        final g = groups[index];
        final color = g.color == null
            ? null
            : ensureContrast(g.color!, context.qio.surface);
        return Padding(
          key: ValueKey('group-row-${g.id}'),
          padding: const EdgeInsets.only(bottom: 8),
          child: Semantics(
            customSemanticsActions: {
              if (index > 0)
                CustomSemanticsAction(label: l10n.groupMoveUp): () =>
                    _reorder(context, groups, index, index - 1),
              if (index < groups.length - 1)
                CustomSemanticsAction(label: l10n.groupMoveDown): () =>
                    _reorder(context, groups, index, index + 1),
            },
            child: QioCard(
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Semantics(
                      label: l10n.groupReorderHandle(g.name),
                      child: const SizedBox(
                        width: 40,
                        height: 48,
                        child: Icon(Icons.drag_indicator),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.folder_outlined,
                    color: color ?? context.qio.primaryText,
                  ),
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
                    tooltip: l10n.groupColorOf(g.name),
                    icon: Icon(
                      Icons.circle,
                      size: 20,
                      color: color ?? context.qio.gray500,
                    ),
                    onPressed: () => _pickColor(context, g),
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
        );
      },
    );
  }
}

class _ColorChoice {
  const _ColorChoice(this.hex);

  final String? hex;
}
