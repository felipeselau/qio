import '../models/history_entry.dart';
import 'history_metrics.dart';

List<int> hourlyDistribution(List<HistoryEntry> entries) {
  final counts = List<int>.filled(24, 0);
  for (final e in entries) {
    counts[e.joinedAt.hour]++;
  }
  return counts;
}

List<int> peakHours(List<int> distribution, {int top = 3}) {
  final hours = [
    for (var h = 0; h < distribution.length; h++)
      if (distribution[h] > 0) h,
  ];
  hours.sort((a, b) {
    final byCount = distribution[b].compareTo(distribution[a]);
    return byCount != 0 ? byCount : a.compareTo(b);
  });
  return hours.take(top).toList();
}

class QueueActivity {
  const QueueActivity({
    required this.queueId,
    required this.name,
    required this.metrics,
  });

  final String queueId;
  final String name;
  final HistoryMetrics metrics;
}

List<QueueActivity> rankByActivity(List<QueueActivity> items) {
  final sorted = [...items]
    ..sort((a, b) {
      final byTotal = b.metrics.total.compareTo(a.metrics.total);
      return byTotal != 0 ? byTotal : a.name.compareTo(b.name);
    });
  return sorted;
}

List<int> weekdayDistribution(List<HistoryEntry> entries) {
  final counts = List<int>.filled(7, 0);
  for (final e in entries) {
    counts[e.joinedAt.weekday - 1]++;
  }
  return counts;
}

List<List<int>> weekdayHourMatrix(List<HistoryEntry> entries) {
  final matrix = [for (var d = 0; d < 7; d++) List<int>.filled(24, 0)];
  for (final e in entries) {
    matrix[e.joinedAt.weekday - 1][e.joinedAt.hour]++;
  }
  return matrix;
}

class DemandPeak {
  const DemandPeak({
    required this.weekday,
    required this.hour,
    required this.count,
  });

  final int weekday;
  final int hour;
  final int count;
}

DemandPeak? peakCell(List<List<int>> matrix) {
  DemandPeak? best;
  for (var d = 0; d < matrix.length; d++) {
    for (var h = 0; h < matrix[d].length; h++) {
      final c = matrix[d][h];
      if (c > 0 && (best == null || c > best.count)) {
        best = DemandPeak(weekday: d, hour: h, count: c);
      }
    }
  }
  return best;
}
