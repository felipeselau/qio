import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/queue.dart';
import '../models/queue_group.dart';
import '../services/queue_analytics.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';

String? _scopeName(
  MetricsScope scope,
  List<QueueGroup> groups,
  List<Queue> queues,
) {
  switch (scope.kind) {
    case MetricsScopeKind.group:
      for (final g in groups) {
        if (g.id == scope.id) return g.name;
      }
    case MetricsScopeKind.queue:
      for (final q in queues) {
        if (q.id == scope.id) return q.name;
      }
    case MetricsScopeKind.all:
    case MetricsScopeKind.ungrouped:
      break;
  }
  return null;
}

String metricsScopeText(
  AppLocalizations l10n,
  MetricsScope scope,
  List<QueueGroup> groups,
  List<Queue> queues,
) {
  final name = _scopeName(scope, groups, queues);
  switch (scope.kind) {
    case MetricsScopeKind.all:
      return l10n.metricsScopeAll;
    case MetricsScopeKind.ungrouped:
      return l10n.metricsScopeUngrouped;
    case MetricsScopeKind.group:
      return l10n.metricsScopeGroup(name ?? '');
    case MetricsScopeKind.queue:
      return l10n.metricsScopeQueue(name ?? '');
  }
}

int _byName(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

class MetricsScopePicker extends StatelessWidget {
  const MetricsScopePicker({
    super.key,
    required this.scope,
    required this.groups,
    required this.queues,
    required this.onChanged,
  });

  final MetricsScope scope;
  final List<QueueGroup> groups;
  final List<Queue> queues;
  final ValueChanged<MetricsScope> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<MetricsScope>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.qio.surface,
      builder: (_) => _ScopeSheet(scope: scope, groups: groups, queues: queues),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (groups.isEmpty) {
      return Semantics(
        label: l10n.metricsScopeLabel,
        child: DropdownButton<MetricsScope>(
          isExpanded: true,
          value: scope,
          onChanged: (v) => onChanged(v ?? MetricsScope.all),
          items: [
            DropdownMenuItem(
              value: MetricsScope.all,
              child: Text(l10n.metricsScopeAll),
            ),
            for (final q in queues)
              DropdownMenuItem(
                value: MetricsScope.queue(q.id),
                child: Text(
                  l10n.metricsScopeQueue(q.name),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      );
    }
    final current = metricsScopeText(l10n, scope, groups, queues);
    return Semantics(
      button: true,
      label: '${l10n.metricsScopeLabel}: $current',
      child: ExcludeSemantics(
        child: InkWell(
          key: const ValueKey('scope-picker'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => _open(context),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: context.qio.gray300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: context.qio.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    current,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.qioText.body,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: context.qio.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScopeSheet extends StatefulWidget {
  const _ScopeSheet({
    required this.scope,
    required this.groups,
    required this.queues,
  });

  final MetricsScope scope;
  final List<QueueGroup> groups;
  final List<Queue> queues;

  @override
  State<_ScopeSheet> createState() => _ScopeSheetState();
}

class _ScopeSheetState extends State<_ScopeSheet> {
  String _query = '';

  bool _matches(String text) => text.toLowerCase().contains(_query);

  Widget _tile(
    BuildContext context, {
    required MetricsScope value,
    required String title,
    String? subtitle,
    IconData? icon,
    double indent = 0,
  }) {
    final selected = widget.scope == value;
    return ListTile(
      key: ValueKey('scope-${value.kind.name}-${value.id ?? ''}'),
      selected: selected,
      minVerticalPadding: 8,
      contentPadding: EdgeInsets.only(left: 16 + indent, right: 16),
      leading: icon == null ? null : Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: () => Navigator.of(context).pop(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groups = [...widget.groups]..sort((a, b) => _byName(a.name, b.name));
    final byGroup = <String?, List<Queue>>{};
    for (final q in widget.queues) {
      byGroup.putIfAbsent(resolveGroupId(q, widget.groups), () => []).add(q);
    }
    for (final list in byGroup.values) {
      list.sort((a, b) => _byName(a.name, b.name));
    }
    final tiles = <Widget>[];
    if (_query.isEmpty || _matches(l10n.metricsScopeAll)) {
      tiles.add(
        _tile(
          context,
          value: MetricsScope.all,
          title: l10n.metricsScopeAll,
          icon: Icons.layers_outlined,
        ),
      );
    }

    void block({
      required MetricsScope scope,
      required String name,
      required IconData icon,
      required List<Queue> queues,
    }) {
      final groupHit = _query.isEmpty || _matches(name);
      final shown = groupHit
          ? queues
          : [
              for (final q in queues)
                if (_matches(q.name)) q,
            ];
      if (!groupHit && shown.isEmpty) return;
      tiles.add(
        _tile(
          context,
          value: scope,
          title: name,
          subtitle: l10n.metricsGroupQueues(queues.length),
          icon: icon,
        ),
      );
      for (final q in shown) {
        tiles.add(
          _tile(
            context,
            value: MetricsScope.queue(q.id),
            title: q.name,
            indent: 40,
          ),
        );
      }
    }

    for (final g in groups) {
      block(
        scope: MetricsScope.group(g.id),
        name: g.name,
        icon: Icons.folder_outlined,
        queues: byGroup[g.id] ?? const [],
      );
    }
    final ungrouped = byGroup[null];
    if (ungrouped != null) {
      block(
        scope: MetricsScope.ungrouped,
        name: l10n.groupNone,
        icon: Icons.folder_off_outlined,
        queues: ungrouped,
      );
    }
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.scopePickerTitle,
                        style: context.qioText.heading3,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.close,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const ValueKey('scope-search'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.scopeSearchHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: tiles.isEmpty
                  ? Center(
                      child: Text(
                        l10n.scopeNoResults,
                        style: context.qioText.body,
                      ),
                    )
                  : ListView(children: tiles),
            ),
          ],
        ),
      ),
    );
  }
}
