import 'package:shared_preferences/shared_preferences.dart';

import '../models/queue.dart';

enum QueueSort { name, recent, waiting }

const int queueToolsThreshold = 5;

bool showQueueTools(int queueCount) => queueCount > queueToolsThreshold;

const _folded = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
};

String foldForSearch(String input) {
  final lower = input.trim().toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    out.write(_folded[ch] ?? ch);
  }
  return out.toString();
}

List<Queue> filterAndSortQueues(
  List<Queue> queues, {
  String query = '',
  QueueSort sort = QueueSort.name,
  Map<String, int> waiting = const {},
}) {
  final needle = foldForSearch(query);
  final result = needle.isEmpty
      ? List<Queue>.of(queues)
      : queues.where((q) => foldForSearch(q.name).contains(needle)).toList();
  int byName(Queue a, Queue b) =>
      foldForSearch(a.name).compareTo(foldForSearch(b.name));
  result.sort((a, b) {
    switch (sort) {
      case QueueSort.name:
        return byName(a, b);
      case QueueSort.recent:
        final c = b.createdAt.compareTo(a.createdAt);
        return c != 0 ? c : byName(a, b);
      case QueueSort.waiting:
        final c = (waiting[b.id] ?? 0).compareTo(waiting[a.id] ?? 0);
        return c != 0 ? c : byName(a, b);
    }
  });
  return result;
}

class QueueSortPrefs {
  static const key = 'home_queue_sort';

  static Future<QueueSort> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(key);
      return QueueSort.values.firstWhere(
        (s) => s.name == saved,
        orElse: () => QueueSort.name,
      );
    } catch (_) {
      return QueueSort.name;
    }
  }

  static Future<void> save(QueueSort sort) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, sort.name);
    } catch (_) {
      return;
    }
  }
}
