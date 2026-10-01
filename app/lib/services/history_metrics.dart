import '../models/history_entry.dart';

enum HistoryPeriod { today, last7Days, all }

extension HistoryPeriodX on HistoryPeriod {
  String get label {
    switch (this) {
      case HistoryPeriod.today:
        return 'Hoje';
      case HistoryPeriod.last7Days:
        return '7 dias';
      case HistoryPeriod.all:
        return 'Tudo';
    }
  }
}

class HistoryMetrics {
  const HistoryMetrics({
    required this.total,
    required this.served,
    required this.noShow,
    required this.left,
    required this.noShowRate,
    this.avgWaitMin,
    this.avgServiceMin,
  });

  final int total;
  final int served;
  final int noShow;
  final int left;
  final double noShowRate;
  final double? avgWaitMin;
  final double? avgServiceMin;
}

List<HistoryEntry> filterHistory(
  List<HistoryEntry> entries, {
  String? result,
  HistoryPeriod period = HistoryPeriod.all,
  required DateTime now,
}) {
  final startOfToday = DateTime(now.year, now.month, now.day);
  final cutoff = switch (period) {
    HistoryPeriod.today => startOfToday,
    HistoryPeriod.last7Days => now.subtract(const Duration(days: 7)),
    HistoryPeriod.all => null,
  };
  return entries.where((e) {
    if (result != null && e.result != result) return false;
    if (cutoff != null && e.referenceTime.isBefore(cutoff)) return false;
    return true;
  }).toList();
}

double? _averageMinutes(Iterable<Duration> durations) {
  if (durations.isEmpty) return null;
  final totalMs = durations.fold<int>(0, (s, d) => s + d.inMilliseconds);
  return totalMs / durations.length / 60000;
}

HistoryMetrics computeHistoryMetrics(List<HistoryEntry> entries) {
  final served = entries.where((e) => e.isServed).length;
  final noShow = entries.where((e) => e.isNoShow).length;
  final left = entries.where((e) => e.isLeft).length;
  final total = entries.length;
  final waits = entries.map((e) => e.wait).whereType<Duration>();
  final services = entries
      .where((e) => e.isServed)
      .map((e) => e.service)
      .whereType<Duration>();
  return HistoryMetrics(
    total: total,
    served: served,
    noShow: noShow,
    left: left,
    noShowRate: total == 0 ? 0 : noShow / total,
    avgWaitMin: _averageMinutes(waits),
    avgServiceMin: _averageMinutes(services),
  );
}
