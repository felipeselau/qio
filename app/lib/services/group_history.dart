import '../models/history_entry.dart';
import '../models/queue_feedback.dart';
import 'queue_analytics.dart';

const groupHistoryPageSize = 50;

class GroupHistorySlice {
  const GroupHistorySlice({
    required this.queueId,
    required this.queueName,
    required this.entries,
    this.feedback = const [],
  });

  final String queueId;
  final String queueName;
  final List<HistoryEntry> entries;
  final List<QueueFeedback> feedback;
}

class GroupHistoryItem {
  const GroupHistoryItem({
    required this.entry,
    required this.queueId,
    required this.queueName,
  });

  final HistoryEntry entry;
  final String queueId;
  final String queueName;
}

class GroupHistory {
  const GroupHistory({
    required this.items,
    required this.truncatedQueueNames,
    required this.feedback,
    required this.queueCount,
  });

  static const empty = GroupHistory(
    items: [],
    truncatedQueueNames: [],
    feedback: [],
    queueCount: 0,
  );

  final List<GroupHistoryItem> items;
  final List<String> truncatedQueueNames;
  final List<QueueFeedback> feedback;
  final int queueCount;

  bool get truncated => truncatedQueueNames.isNotEmpty;
}

int compareGroupHistoryItems(GroupHistoryItem a, GroupHistoryItem b) {
  final byTime = b.entry.referenceTime.compareTo(a.entry.referenceTime);
  if (byTime != 0) return byTime;
  final byQueue = a.queueName.compareTo(b.queueName);
  if (byQueue != 0) return byQueue;
  final byTicket = b.entry.ticket.compareTo(a.entry.ticket);
  if (byTicket != 0) return byTicket;
  final byQueueId = a.queueId.compareTo(b.queueId);
  return byQueueId != 0 ? byQueueId : a.entry.id.compareTo(b.entry.id);
}

GroupHistory mergeGroupHistory(
  Iterable<GroupHistorySlice> slices, {
  int limitPerQueue = defaultHistoryLimit,
}) {
  final items = <GroupHistoryItem>[];
  final truncated = <String>[];
  final feedback = <QueueFeedback>[];
  var count = 0;
  for (final s in slices) {
    count++;
    final sorted = [...s.entries]
      ..sort((a, b) => b.referenceTime.compareTo(a.referenceTime));
    if (sorted.length >= limitPerQueue) truncated.add(s.queueName);
    final kept = sorted.take(limitPerQueue);
    final keptIds = {for (final e in kept) e.id};
    for (final e in kept) {
      items.add(
        GroupHistoryItem(entry: e, queueId: s.queueId, queueName: s.queueName),
      );
    }
    feedback.addAll(s.feedback.where((f) => keptIds.contains(f.entryId)));
  }
  items.sort(compareGroupHistoryItems);
  return GroupHistory(
    items: items,
    truncatedQueueNames: truncated,
    feedback: feedback,
    queueCount: count,
  );
}

List<T> pageOf<T>(
  List<T> items,
  int page, {
  int pageSize = groupHistoryPageSize,
}) {
  final end = (page + 1) * pageSize;
  return end >= items.length ? items : items.sublist(0, end);
}
