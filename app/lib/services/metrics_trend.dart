import '../models/history_entry.dart';
import 'history_metrics.dart';

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

class DateRange {
  const DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  int get days => DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  DateRange previous() {
    final n = days;
    return DateRange(DateTime(start.year, start.month, start.day - n), start);
  }

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange($start, $end)';
}

DateRange? rangeFor(HistoryPeriod period, DateTime now, {DateRange? custom}) {
  final today = _dayStart(now);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  switch (period) {
    case HistoryPeriod.today:
      return DateRange(today, tomorrow);
    case HistoryPeriod.last7Days:
      return DateRange(DateTime(now.year, now.month, now.day - 6), tomorrow);
    case HistoryPeriod.last30Days:
      return DateRange(DateTime(now.year, now.month, now.day - 29), tomorrow);
    case HistoryPeriod.custom:
      if (custom == null) return null;
      var start = _dayStart(custom.start);
      var end = _dayStart(custom.end);
      if (end.isBefore(start)) {
        final swap = start;
        start = end;
        end = swap;
      }
      if (end == start) end = DateTime(end.year, end.month, end.day + 1);
      return DateRange(start, end);
    case HistoryPeriod.all:
      return null;
  }
}

class DayPoint {
  const DayPoint({
    required this.day,
    required this.total,
    required this.served,
    required this.noShow,
    required this.noShowRate,
    this.avgWaitMin,
  });

  final DateTime day;
  final int total;
  final int served;
  final int noShow;
  final double noShowRate;
  final double? avgWaitMin;
}

List<DayPoint> dailySeries(List<HistoryEntry> entries, DateRange range) {
  final byDay = <DateTime, List<HistoryEntry>>{};
  for (final e in entries) {
    final t = e.referenceTime;
    if (!range.contains(t)) continue;
    byDay.putIfAbsent(_dayStart(t), () => []).add(e);
  }
  final points = <DayPoint>[];
  for (var i = 0; i < range.days; i++) {
    final day = DateTime(
      range.start.year,
      range.start.month,
      range.start.day + i,
    );
    final m = computeHistoryMetrics(byDay[day] ?? const []);
    points.add(
      DayPoint(
        day: day,
        total: m.total,
        served: m.served,
        noShow: m.noShow,
        noShowRate: m.noShowRate,
        avgWaitMin: m.avgWaitMin,
      ),
    );
  }
  return points;
}

({double avg, DayPoint? peak}) trendStats(List<DayPoint> series) {
  if (series.isEmpty) return (avg: 0, peak: null);
  var total = 0;
  DayPoint? peak;
  for (final p in series) {
    total += p.total;
    if (p.total > 0 && (peak == null || p.total > peak.total)) peak = p;
  }
  return (avg: total / series.length, peak: peak);
}

enum MetricKey { total, noShowRate, avgWait, avgService, waitMedian, waitP90 }

class Delta {
  const Delta({required this.abs, this.pct});

  final double abs;
  final double? pct;
}

Map<MetricKey, Delta> compare(
  HistoryMetrics cur,
  HistoryMetrics prev, {
  WaitStats? curWait,
  WaitStats? prevWait,
}) {
  if (prev.total == 0) return const {};
  final out = <MetricKey, Delta>{};
  void relative(MetricKey key, num? c, num? p) {
    if (c == null || p == null || p == 0) return;
    out[key] = Delta(abs: (c - p).toDouble(), pct: (c - p) / p * 100);
  }

  relative(MetricKey.total, cur.total, prev.total);
  out[MetricKey.noShowRate] = Delta(
    abs: (cur.noShowRate - prev.noShowRate) * 100,
    pct: prev.noShowRate == 0
        ? null
        : (cur.noShowRate - prev.noShowRate) / prev.noShowRate * 100,
  );
  relative(MetricKey.avgWait, cur.avgWaitMin, prev.avgWaitMin);
  relative(MetricKey.avgService, cur.avgServiceMin, prev.avgServiceMin);
  relative(MetricKey.waitMedian, curWait?.medianMin, prevWait?.medianMin);
  relative(MetricKey.waitP90, curWait?.p90Min, prevWait?.p90Min);
  return out;
}
