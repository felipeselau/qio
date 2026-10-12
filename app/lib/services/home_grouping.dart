import 'package:shared_preferences/shared_preferences.dart';

import '../models/queue.dart';
import '../models/queue_group.dart';
import 'group_service.dart';

const ungroupedSectionId = '__ungrouped__';

class HomeSection {
  const HomeSection({required this.group, required this.queues});

  final QueueGroup? group;
  final List<Queue> queues;

  String get id => group?.id ?? ungroupedSectionId;
}

List<HomeSection> buildHomeSections(
  List<Queue> owned,
  List<QueueGroup> groups,
) {
  final byGroup = <String, List<Queue>>{};
  final ungrouped = <Queue>[];
  for (final q in owned) {
    final id = resolveGroupId(q, groups);
    if (id == null) {
      ungrouped.add(q);
    } else {
      byGroup.putIfAbsent(id, () => []).add(q);
    }
  }
  if (byGroup.isEmpty) return const [];
  return [
    for (final g in sortGroups(groups))
      if (byGroup.containsKey(g.id))
        HomeSection(group: g, queues: byGroup[g.id]!),
    if (ungrouped.isNotEmpty) HomeSection(group: null, queues: ungrouped),
  ];
}

int sumWaiting(Iterable<Queue> queues, Map<String, int> waiting) =>
    queues.fold(0, (sum, q) => sum + (waiting[q.id] ?? 0));

abstract class GroupCollapseStore {
  Future<Set<String>> load(String uid);
  Future<void> save(String uid, Set<String> collapsed);
}

class SharedPrefsGroupCollapseStore implements GroupCollapseStore {
  const SharedPrefsGroupCollapseStore();

  static String keyFor(String uid) => 'home_collapsed_groups_$uid';

  @override
  Future<Set<String>> load(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(keyFor(uid)) ?? const []).toSet();
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> save(String uid, Set<String> collapsed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(keyFor(uid), collapsed.toList()..sort());
    } catch (_) {
      return;
    }
  }
}
