import '../l10n/app_localizations.dart';
import '../models/history_entry.dart';
import 'metrics_trend.dart';

enum HistoryPeriod { today, last7Days, last30Days, custom, all }

extension HistoryPeriodX on HistoryPeriod {
  String label(AppLocalizations l10n) {
    switch (this) {
      case HistoryPeriod.today:
        return l10n.periodToday;
      case HistoryPeriod.last7Days:
        return l10n.period7Days;
      case HistoryPeriod.last30Days:
        return l10n.period30Days;
      case HistoryPeriod.custom:
        return l10n.periodCustom;
      case HistoryPeriod.all:
        return l10n.periodAll;
    }
  }

  String get fileSlug {
    switch (this) {
      case HistoryPeriod.today:
        return 'hoje';
      case HistoryPeriod.last7Days:
        return '7dias';
      case HistoryPeriod.last30Days:
        return '30dias';
      case HistoryPeriod.custom:
        return 'personalizado';
      case HistoryPeriod.all:
        return 'tudo';
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
  DateRange? custom,
}) {
  if (period == HistoryPeriod.custom && custom == null) return [];
  final range = rangeFor(period, now, custom: custom);
  return entries.where((e) {
    if (result != null && e.result != result) return false;
    if (range != null && !range.contains(e.referenceTime)) return false;
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
  final left = entries.where((e) => e.isLeft && !e.isSystemRemoved).length;
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

const waitBucketEdgesMin = [5, 15, 30];

class WaitStats {
  const WaitStats({
    required this.samples,
    this.medianMin,
    this.p90Min,
    this.avgMin,
    required this.bucketCounts,
  });

  final int samples;
  final double? medianMin;
  final double? p90Min;
  final double? avgMin;
  final List<int> bucketCounts;
}

double _percentile(List<double> sorted, double p) =>
    sorted[(p * sorted.length).ceil() - 1];

WaitStats computeWaitStats(List<HistoryEntry> entries) {
  final waits = <double>[];
  for (final e in entries) {
    if (e.isLeft || e.calledAt == null) continue;
    final ms = e.calledAt!.difference(e.joinedAt).inMilliseconds;
    if (ms < 0) continue;
    waits.add(ms / 60000);
  }
  waits.sort();
  final buckets = List<int>.filled(waitBucketEdgesMin.length + 1, 0);
  for (final w in waits) {
    var i = 0;
    while (i < waitBucketEdgesMin.length && w >= waitBucketEdgesMin[i]) {
      i++;
    }
    buckets[i]++;
  }
  final n = waits.length;
  if (n == 0) return WaitStats(samples: 0, bucketCounts: buckets);
  final median = n.isOdd
      ? waits[n ~/ 2]
      : (waits[n ~/ 2 - 1] + waits[n ~/ 2]) / 2;
  return WaitStats(
    samples: n,
    medianMin: median,
    p90Min: n >= 5 ? _percentile(waits, 0.9) : null,
    avgMin: waits.fold<double>(0, (s, w) => s + w) / n,
    bucketCounts: buckets,
  );
}

class CallEffortStats {
  const CallEffortStats({
    required this.called,
    required this.recallsTotal,
    required this.recalledEntries,
    required this.skipsTotal,
    required this.skippedEntries,
    this.recallRate,
  });

  final int called;
  final int recallsTotal;
  final int recalledEntries;
  final int skipsTotal;
  final int skippedEntries;
  final double? recallRate;
}

CallEffortStats computeCallEffort(List<HistoryEntry> entries) {
  final active = entries.where((e) => !e.isLeft).toList();
  final called = active.where((e) => e.calledAt != null).length;
  final recalled = active.where((e) => e.recalls > 0).length;
  final skipped = active.where((e) => e.skips > 0).length;
  return CallEffortStats(
    called: called,
    recallsTotal: active.fold<int>(0, (s, e) => s + e.recalls),
    recalledEntries: recalled,
    skipsTotal: active.fold<int>(0, (s, e) => s + e.skips),
    skippedEntries: skipped,
    recallRate: called == 0 ? null : recalled / called,
  );
}
