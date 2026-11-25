import '../models/history_entry.dart';
import '../models/queue_feedback.dart';
import 'operator_metrics.dart';
import 'sp_time.dart';

const int defaultIdleCapMin = 30;
const int defaultMinRateSamples = 3;
const int defaultMinWindowMin = 30;

enum Shift { morning, afternoon, night }

Shift shiftOfHour(int hour) {
  if (hour >= 6 && hour < 12) return Shift.morning;
  if (hour >= 12 && hour < 18) return Shift.afternoon;
  return Shift.night;
}

String? _attendantKey(HistoryEntry e, Set<String> ownerUids) {
  final id = e.attendantId;
  return id == null || ownerUids.contains(id) ? null : id;
}

Map<String?, List<HistoryEntry>> _groupHandled(
  Iterable<HistoryEntry> entries,
  Set<String> ownerUids,
) {
  final groups = <String?, List<HistoryEntry>>{};
  for (final e in entries) {
    if (!e.isServed && !e.isNoShow) continue;
    groups.putIfAbsent(_attendantKey(e, ownerUids), () => []).add(e);
  }
  return groups;
}

int _compareIds(String? a, String? b) {
  if (a == b) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  return a.compareTo(b);
}

class OperatorThroughput {
  const OperatorThroughput({
    required this.attendantId,
    required this.total,
    required this.byHour,
    required this.byDay,
    required this.byShift,
  });

  final String? attendantId;
  final int total;
  final List<int> byHour;
  final Map<DateTime, int> byDay;
  final Map<Shift, int> byShift;

  bool get isOwner => attendantId == null;
}

List<OperatorThroughput> computeOperatorThroughput(
  List<HistoryEntry> entries, {
  Set<String> ownerUids = const {},
}) {
  final groups = <String?, List<HistoryEntry>>{};
  for (final e in entries) {
    if (!e.isServed) continue;
    if ((e.finishedAt ?? e.calledAt) == null) continue;
    groups.putIfAbsent(_attendantKey(e, ownerUids), () => []).add(e);
  }
  final out = <OperatorThroughput>[];
  for (final g in groups.entries) {
    final byHour = List<int>.filled(24, 0);
    final days = <DateTime, int>{};
    final shifts = {for (final s in Shift.values) s: 0};
    for (final e in g.value) {
      final t = e.finishedAt ?? e.calledAt!;
      final h = spHour(t);
      byHour[h]++;
      final d = spDay(t);
      days[d] = (days[d] ?? 0) + 1;
      final s = shiftOfHour(h);
      shifts[s] = shifts[s]! + 1;
    }
    final sortedDays = {
      for (final k in (days.keys.toList()..sort())) k: days[k]!,
    };
    out.add(
      OperatorThroughput(
        attendantId: g.key,
        total: g.value.length,
        byHour: byHour,
        byDay: sortedDays,
        byShift: shifts,
      ),
    );
  }
  out.sort((a, b) {
    final byTotal = b.total.compareTo(a.total);
    return byTotal != 0 ? byTotal : _compareIds(a.attendantId, b.attendantId);
  });
  return out;
}

class _Handled {
  const _Handled(this.entry, this.called, this.finished);
  final HistoryEntry entry;
  final DateTime called;
  final DateTime finished;
}

Map<DateTime, List<_Handled>> _byCallDay(List<HistoryEntry> entries) {
  final days = <DateTime, List<_Handled>>{};
  for (final e in entries) {
    final c = e.calledAt;
    final f = e.finishedAt;
    if (c == null || f == null || f.isBefore(c)) continue;
    days.putIfAbsent(spDay(c), () => []).add(_Handled(e, c, f));
  }
  for (final list in days.values) {
    list.sort((a, b) {
      final byCall = a.called.compareTo(b.called);
      return byCall != 0 ? byCall : a.finished.compareTo(b.finished);
    });
  }
  return days;
}

DateTime _lastFinish(List<_Handled> list) =>
    list.map((h) => h.finished).reduce((a, b) => a.isAfter(b) ? a : b);

class OperatorDayRate {
  const OperatorDayRate({
    required this.day,
    required this.served,
    required this.windowHours,
    this.perHour,
  });

  final DateTime day;
  final int served;
  final double windowHours;
  final double? perHour;
}

class OperatorRate {
  const OperatorRate({
    required this.attendantId,
    required this.days,
    required this.served,
    required this.windowHours,
    this.perHour,
  });

  final String? attendantId;
  final List<OperatorDayRate> days;
  final int served;
  final double windowHours;
  final double? perHour;

  bool get isOwner => attendantId == null;
}

List<OperatorRate> computeOperatorRates(
  List<HistoryEntry> entries, {
  Set<String> ownerUids = const {},
  int minSamples = defaultMinRateSamples,
  int minWindowMin = defaultMinWindowMin,
}) {
  final out = <OperatorRate>[];
  for (final g in _groupHandled(entries, ownerUids).entries) {
    final days = <OperatorDayRate>[];
    var served = 0;
    var hours = 0.0;
    final byDay = _byCallDay(g.value);
    for (final day in byDay.keys.toList()..sort()) {
      final list = byDay[day]!;
      final span = _lastFinish(list).difference(list.first.called);
      final dayHours = span.inMilliseconds / 3600000;
      final dayServed = list.where((h) => h.entry.isServed).length;
      final ok =
          dayServed >= minSamples && span >= Duration(minutes: minWindowMin);
      days.add(
        OperatorDayRate(
          day: day,
          served: dayServed,
          windowHours: dayHours,
          perHour: ok ? dayServed / dayHours : null,
        ),
      );
      if (ok) {
        served += dayServed;
        hours += dayHours;
      }
    }
    out.add(
      OperatorRate(
        attendantId: g.key,
        days: days,
        served: served,
        windowHours: hours,
        perHour: hours > 0 ? served / hours : null,
      ),
    );
  }
  out.sort((a, b) => _compareIds(a.attendantId, b.attendantId));
  return out;
}

class OperatorIdle {
  const OperatorIdle({
    required this.attendantId,
    required this.idleMin,
    required this.gaps,
    required this.observedMin,
    this.idlePct,
  });

  final String? attendantId;
  final double idleMin;
  final int gaps;
  final double observedMin;
  final double? idlePct;

  bool get isOwner => attendantId == null;
}

List<OperatorIdle> computeOperatorIdle(
  List<HistoryEntry> entries, {
  Set<String> ownerUids = const {},
  int idleCapMin = defaultIdleCapMin,
}) {
  final cap = Duration(minutes: idleCapMin);
  final out = <OperatorIdle>[];
  final valid = entries.where((e) => e.joinedAt.millisecondsSinceEpoch != 0);
  for (final g in _groupHandled(valid, ownerUids).entries) {
    var idleMs = 0;
    var observedMs = 0;
    var gaps = 0;
    for (final list in _byCallDay(g.value).values) {
      observedMs += _lastFinish(
        list,
      ).difference(list.first.called).inMilliseconds;
      var maxFinish = list.first.finished;
      for (var i = 1; i < list.length; i++) {
        final next = list[i];
        final gap = next.called.difference(maxFinish);
        final counts =
            gap > Duration.zero &&
            gap <= cap &&
            spDay(maxFinish) == spDay(next.called) &&
            !next.entry.joinedAt.isAfter(maxFinish);
        if (counts) {
          idleMs += gap.inMilliseconds;
          gaps++;
        }
        if (next.finished.isAfter(maxFinish)) maxFinish = next.finished;
      }
    }
    out.add(
      OperatorIdle(
        attendantId: g.key,
        idleMin: idleMs / 60000,
        gaps: gaps,
        observedMin: observedMs / 60000,
        idlePct: observedMs > 0 ? idleMs / observedMs : null,
      ),
    );
  }
  out.sort((a, b) => _compareIds(a.attendantId, b.attendantId));
  return out;
}

class OperatorComparison {
  const OperatorComparison({required this.stats, this.deviationPct, this.rank});

  final OperatorStats stats;
  final double? deviationPct;
  final int? rank;
}

class OperatorComparisonReport {
  const OperatorComparisonReport({required this.rows, this.scopeAvgMin});

  final List<OperatorComparison> rows;
  final double? scopeAvgMin;
}

OperatorComparisonReport compareOperators(
  List<OperatorStats> stats, {
  int minSamples = minServiceSamples,
}) {
  bool ok(OperatorStats s) =>
      s.avgServiceMin != null && s.serviceSamples >= minSamples;
  final qualified = stats.where(ok).toList();
  var samples = 0;
  var weighted = 0.0;
  for (final s in qualified) {
    samples += s.serviceSamples;
    weighted += s.avgServiceMin! * s.serviceSamples;
  }
  final scopeAvg = samples > 0 ? weighted / samples : null;
  final order =
      [
        for (var i = 0; i < stats.length; i++)
          if (ok(stats[i])) i,
      ]..sort((x, y) {
        final a = stats[x];
        final b = stats[y];
        final byAvg = a.avgServiceMin!.compareTo(b.avgServiceMin!);
        if (byAvg != 0) return byAvg;
        final byVolume = b.volume.compareTo(a.volume);
        return byVolume != 0
            ? byVolume
            : _compareIds(a.attendantId, b.attendantId);
      });
  final rankOf = {for (var r = 0; r < order.length; r++) order[r]: r + 1};
  final rows = <OperatorComparison>[];
  for (var i = 0; i < stats.length; i++) {
    final s = stats[i];
    if (!ok(s) || scopeAvg == null || scopeAvg <= 0) {
      rows.add(OperatorComparison(stats: s));
      continue;
    }
    rows.add(
      OperatorComparison(
        stats: s,
        deviationPct: (s.avgServiceMin! - scopeAvg) / scopeAvg * 100,
        rank: rankOf[i],
      ),
    );
  }
  return OperatorComparisonReport(rows: rows, scopeAvgMin: scopeAvg);
}

class AttendantRow {
  const AttendantRow({
    required this.stats,
    required this.byHour,
    required this.byShift,
    this.deviationPct,
    this.rank,
    this.perHour,
    this.idlePct,
  });

  final OperatorStats stats;
  final List<int> byHour;
  final Map<Shift, int> byShift;
  final double? deviationPct;
  final int? rank;
  final double? perHour;
  final double? idlePct;

  String? get attendantId => stats.attendantId;
  bool get isOwner => stats.isOwner;
}

bool isUsableForAttendants(HistoryEntry e) {
  if (e.joinedAt.millisecondsSinceEpoch == 0) return false;
  if (e.isServed && (e.finishedAt ?? e.calledAt) == null) return false;
  return true;
}

List<AttendantRow> buildAttendantRows(
  List<HistoryEntry> allEntries, {
  Set<String> ownerUids = const {},
  Iterable<QueueFeedback> feedback = const [],
  Map<String, String> names = const {},
  String unknownName = '',
}) {
  final entries = allEntries.where(isUsableForAttendants).toList();
  final stats = computeOperatorMetrics(
    entries,
    ownerUids: ownerUids,
    feedback: feedback,
    names: names,
    unknownName: unknownName,
  );
  final comparison = compareOperators(stats).rows;
  final throughput = {
    for (final t in computeOperatorThroughput(entries, ownerUids: ownerUids))
      t.attendantId: t,
  };
  final rates = {
    for (final r in computeOperatorRates(entries, ownerUids: ownerUids))
      r.attendantId: r,
  };
  final idle = {
    for (final i in computeOperatorIdle(entries, ownerUids: ownerUids))
      i.attendantId: i,
  };
  return [
    for (final c in comparison)
      AttendantRow(
        stats: c.stats,
        byHour: throughput[c.stats.attendantId]?.byHour ?? List.filled(24, 0),
        byShift:
            throughput[c.stats.attendantId]?.byShift ??
            {for (final s in Shift.values) s: 0},
        deviationPct: c.deviationPct,
        rank: c.rank,
        perHour: rates[c.stats.attendantId]?.perHour,
        idlePct: c.stats.volume >= defaultMinRateSamples
            ? idle[c.stats.attendantId]?.idlePct
            : null,
      ),
  ];
}

List<int> sumByHour(Iterable<AttendantRow> rows) {
  final out = List<int>.filled(24, 0);
  for (final r in rows) {
    for (var h = 0; h < 24; h++) {
      out[h] += r.byHour[h];
    }
  }
  return out;
}

Map<Shift, int> sumByShift(Iterable<AttendantRow> rows) {
  final out = {for (final s in Shift.values) s: 0};
  for (final r in rows) {
    for (final s in Shift.values) {
      out[s] = out[s]! + (r.byShift[s] ?? 0);
    }
  }
  return out;
}
