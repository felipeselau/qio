import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/queue_group.dart';
import '../services/group_service.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';

class GroupChip extends StatelessWidget {
  const GroupChip({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.groupChipSemantics(name),
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: context.qio.gray100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.qio.gray400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 14, color: context.qio.gray700),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.qioText.caption.copyWith(
                  fontSize: 12,
                  color: context.qio.gray700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PanelGroupChip extends StatefulWidget {
  const PanelGroupChip({super.key, required this.groupId, this.groups});

  final String groupId;
  final GroupService? groups;

  @override
  State<PanelGroupChip> createState() => _PanelGroupChipState();
}

class _PanelGroupChipState extends State<PanelGroupChip> {
  Stream<List<QueueGroup>>? _stream;

  @override
  void initState() {
    super.initState();
    try {
      _stream = (widget.groups ?? GroupService.instance).watchGroups();
    } catch (_) {
      _stream = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _stream;
    if (stream == null) return const SizedBox.shrink();
    return StreamBuilder<List<QueueGroup>>(
      stream: stream,
      builder: (context, snap) {
        final groups = snap.data;
        if (snap.hasError || groups == null) return const SizedBox.shrink();
        final match = groups.where((g) => g.id == widget.groupId);
        if (match.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: GroupChip(name: match.first.name),
          ),
        );
      },
    );
  }
}
