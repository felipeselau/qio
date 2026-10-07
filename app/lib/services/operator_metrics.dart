import '../models/history_entry.dart';
import '../models/queue_feedback.dart';

const int minServiceSamples = 3;

class OperatorStats {
  const OperatorStats({
    required this.attendantId,
    required this.served,
    required this.noShow,
    required this.serviceSamples,
    this.avgServiceMin,
    required this.feedback,
  });

  final String? attendantId;
  final int served;
  final int noShow;
  final int serviceSamples;
  final double? avgServiceMin;
  final FeedbackSummary feedback;

  bool get isOwner => attendantId == null;
  int get volume => served + noShow;
}

List<OperatorStats> computeOperatorMetrics(
  List<HistoryEntry> entries, {
  Set<String> ownerUids = const {},
  Iterable<QueueFeedback> feedback = const [],
  Map<String, String> names = const {},
  String unknownName = '',
}) {
  final groups = <String?, List<HistoryEntry>>{};
  for (final e in entries) {
    if (!e.isServed && !e.isNoShow) continue;
    final id = e.attendantId;
    final key = id == null || ownerUids.contains(id) ? null : id;
    groups.putIfAbsent(key, () => []).add(e);
  }
  final stats = [
    for (final g in groups.entries) _statsFor(g.key, g.value, feedback),
  ];
  String nameOf(OperatorStats s) =>
      (s.attendantId == null ? '' : names[s.attendantId] ?? unknownName)
          .toLowerCase();
  stats.sort((a, b) {
    final byVolume = b.volume.compareTo(a.volume);
    if (byVolume != 0) return byVolume;
    if (a.isOwner != b.isOwner) return a.isOwner ? -1 : 1;
    return nameOf(a).compareTo(nameOf(b));
  });
  return stats;
}

OperatorStats _statsFor(
  String? attendantId,
  List<HistoryEntry> entries,
  Iterable<QueueFeedback> feedback,
) {
  final served = entries.where((e) => e.isServed).toList();
  final durations = served
      .map((e) => e.service)
      .whereType<Duration>()
      .where((d) => !d.isNegative)
      .toList();
  double? avg;
  if (durations.length >= minServiceSamples) {
    final totalMs = durations.fold<int>(0, (s, d) => s + d.inMilliseconds);
    avg = totalMs / durations.length / 60000;
  }
  return OperatorStats(
    attendantId: attendantId,
    served: served.length,
    noShow: entries.where((e) => e.isNoShow).length,
    serviceSamples: durations.length,
    avgServiceMin: avg,
    feedback: summarizeFeedback(
      feedback,
      onlyEntryIds: {for (final e in served) e.id},
    ),
  );
}
