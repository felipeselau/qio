import '../models/queue_entry.dart';

Set<String> waitingIdsOf(Iterable<QueueEntry> entries) => {
  for (final e in entries)
    if (e.status == EntryStatus.waiting) e.id,
};

Set<String> newWaitingIds(
  Set<String>? previousWaiting,
  Iterable<QueueEntry> current,
) {
  if (previousWaiting == null) return {};
  return waitingIdsOf(current).difference(previousWaiting);
}
