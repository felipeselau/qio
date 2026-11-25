import '../models/history_entry.dart';
import 'sp_time.dart';

const double defaultTargetOccupancy = 0.85;
const int defaultMinServiceSamples = 3;
const int defaultDeficitLimit = 5;
const int seasonWeeks = 8;
const int minSeasonWeeks = 3;
const int seasonTopCells = 5;
const int recurrencePct = 70;
const double stableTrendPct = 5;
const Duration _maxPlausibleService = Duration(hours: 24);
const int _hourMs = 3600000;
const String _ownerKey = '';

class StaffingCell {
  const StaffingCell({
    required this.weekday,
    required this.hour,
    required this.arrivals,
    required this.required,
    required this.observed,
  });

  final int weekday;
  final int hour;
  final double arrivals;
  final int required;
  final double observed;

  double get gap => required - observed;
}

class StaffingGrid {
  const StaffingGrid({
    required this.cells,
    required this.topDeficits,
    required this.serviceSamples,
    required this.occupancy,
    required this.coverageDays,
    this.avgServiceMin,
  });

  static final empty = StaffingGrid(
    cells: [
      for (var d = 0; d < 7; d++)
        [
          for (var h = 0; h < 24; h++)
            StaffingCell(
              weekday: d,
              hour: h,
              arrivals: 0,
              required: 0,
              observed: 0,
            ),
        ],
    ],
    topDeficits: const [],
    serviceSamples: 0,
    occupancy: defaultTargetOccupancy,
    coverageDays: 0,
  );

  final List<List<StaffingCell>> cells;
  final List<StaffingCell> topDeficits;
  final double? avgServiceMin;
  final int serviceSamples;
  final double occupancy;
  final int coverageDays;

  bool get hasRequirement => avgServiceMin != null;

  bool get hasArrivals => cells.any((r) => r.any((c) => c.arrivals > 0));
}

DateTime _weekStart(DateTime spDayValue) =>
    spDayValue.subtract(Duration(days: spDayValue.weekday - 1));

int _hourIndex(DateTime t) =>
    ((t.toUtc().millisecondsSinceEpoch - 3 * _hourMs) / _hourMs).floor();

String _operatorKey(HistoryEntry e, Set<String> ownerUids) {
  final id = e.attendantId;
  return id == null || ownerUids.contains(id) ? _ownerKey : id;
}

StaffingGrid computeStaffingGrid(
  Iterable<HistoryEntry> entries, {
  Set<String> ownerUids = const {},
  double occupancy = defaultTargetOccupancy,
  int minServiceSamples = defaultMinServiceSamples,
  int deficitLimit = defaultDeficitLimit,
}) {
  assert(occupancy > 0 && occupancy <= 1, 'occupancy must be in (0, 1]');
  final valid = entries
      .where((e) => e.joinedAt.millisecondsSinceEpoch != 0)
      .toList();
  if (valid.isEmpty) return StaffingGrid.empty;

  final arrivals = [for (var d = 0; d < 7; d++) List<int>.filled(24, 0)];
  var first = spDay(valid.first.joinedAt);
  var last = first;
  void cover(DateTime t) {
    final day = spDay(t);
    if (day.isBefore(first)) first = day;
    if (day.isAfter(last)) last = day;
  }

  var serviceSum = 0.0;
  var serviceSamples = 0;
  final slots = <int, Set<String>>{};
  for (final e in valid) {
    final local = spLocal(e.joinedAt);
    arrivals[local.weekday - 1][local.hour]++;
    cover(e.joinedAt);
    final called = e.calledAt;
    if (called == null || !(e.isServed || e.isNoShow)) continue;
    cover(called);
    final finished = e.finishedAt;
    final end = finished != null && finished.isAfter(called)
        ? finished
        : called;
    var startIdx = _hourIndex(called);
    var endIdx = end.isAfter(called)
        ? _hourIndex(end.subtract(const Duration(milliseconds: 1)))
        : startIdx;
    if (endIdx < startIdx) endIdx = startIdx;
    if (endIdx > startIdx + 23) endIdx = startIdx + 23;
    final key = _operatorKey(e, ownerUids);
    for (; startIdx <= endIdx; startIdx++) {
      slots.putIfAbsent(startIdx, () => {}).add(key);
    }
    if (e.isServed) {
      final s = e.service;
      if (s != null && !s.isNegative && s <= _maxPlausibleService) {
        serviceSum += s.inMilliseconds / 60000;
        serviceSamples++;
      }
    }
  }

  final occurrences = List<int>.filled(7, 0);
  for (
    var day = first;
    !day.isAfter(last);
    day = day.add(const Duration(days: 1))
  ) {
    occurrences[day.weekday - 1]++;
  }

  final observedSum = [for (var d = 0; d < 7; d++) List<int>.filled(24, 0)];
  for (final slot in slots.entries) {
    final at = DateTime.fromMillisecondsSinceEpoch(
      slot.key * _hourMs,
      isUtc: true,
    );
    observedSum[at.weekday - 1][at.hour] += slot.value.length;
  }

  final avg = serviceSamples >= minServiceSamples
      ? serviceSum / serviceSamples
      : null;
  final cells = <List<StaffingCell>>[];
  final deficits = <StaffingCell>[];
  for (var d = 0; d < 7; d++) {
    final row = <StaffingCell>[];
    final occ = occurrences[d];
    for (var h = 0; h < 24; h++) {
      final perHour = occ == 0 ? 0.0 : arrivals[d][h] / occ;
      var needed = 0;
      if (avg != null && perHour > 0) {
        needed = (perHour * avg / 60 / occupancy - 1e-9).ceil();
        if (needed < 1) needed = 1;
      }
      final cell = StaffingCell(
        weekday: d,
        hour: h,
        arrivals: perHour,
        required: needed,
        observed: occ == 0 ? 0.0 : observedSum[d][h] / occ,
      );
      row.add(cell);
      if (cell.required > 0 && cell.gap > 0) deficits.add(cell);
    }
    cells.add(row);
  }
  deficits.sort((a, b) {
    final byGap = b.gap.compareTo(a.gap);
    if (byGap != 0) return byGap;
    final byReq = b.required.compareTo(a.required);
    if (byReq != 0) return byReq;
    final byDay = a.weekday.compareTo(b.weekday);
    return byDay != 0 ? byDay : a.hour.compareTo(b.hour);
  });
  return StaffingGrid(
    cells: cells,
    topDeficits: deficits.take(deficitLimit).toList(),
    avgServiceMin: avg,
    serviceSamples: serviceSamples,
    occupancy: occupancy,
    coverageDays: last.difference(first).inDays + 1,
  );
}

class WeekVolume {
  const WeekVolume(this.weekStart, this.volume);

  final DateTime weekStart;
  final int volume;
}

class RecurringCell {
  const RecurringCell({
    required this.weekday,
    required this.hour,
    required this.weeks,
    required this.observedWeeks,
  });

  final int weekday;
  final int hour;
  final int weeks;
  final int observedWeeks;
}

enum TrendDirection { up, down, stable }

class SeasonalityReport {
  const SeasonalityReport({
    required this.weeks,
    required this.recurring,
    this.trendPct,
    this.direction,
  });

  static const empty = SeasonalityReport(weeks: [], recurring: []);

  final List<WeekVolume> weeks;
  final List<RecurringCell> recurring;
  final double? trendPct;
  final TrendDirection? direction;

  int get observedWeeks => weeks.length;

  bool get insufficient => observedWeeks < minSeasonWeeks;
}

SeasonalityReport computeSeasonality(
  Iterable<HistoryEntry> entries, {
  required DateTime now,
  int weeks = seasonWeeks,
  int minWeeks = minSeasonWeeks,
  int topCells = seasonTopCells,
  int recurrenceMinPct = recurrencePct,
}) {
  final currentMonday = _weekStart(spDay(now));
  final windowStart = currentMonday.subtract(Duration(days: 7 * weeks));
  final volumes = List<int>.filled(weeks, 0);
  final cellCounts = [for (var i = 0; i < weeks; i++) List<int>.filled(168, 0)];
  for (final e in entries) {
    if (e.joinedAt.millisecondsSinceEpoch == 0) continue;
    final day = spDay(e.joinedAt);
    if (day.isBefore(windowStart) || !day.isBefore(currentMonday)) continue;
    final idx = day.difference(windowStart).inDays ~/ 7;
    volumes[idx]++;
    cellCounts[idx][(day.weekday - 1) * 24 + spHour(e.joinedAt)]++;
  }
  final firstIdx = volumes.indexWhere((v) => v > 0);
  if (firstIdx < 0) return SeasonalityReport.empty;
  final observed = [
    for (var i = firstIdx; i < weeks; i++)
      WeekVolume(windowStart.add(Duration(days: 7 * i)), volumes[i]),
  ];
  if (observed.length < minWeeks) {
    return SeasonalityReport(weeks: observed, recurring: const []);
  }

  final n = observed.length;
  final mean = observed.fold<int>(0, (s, w) => s + w.volume) / n;
  final xMean = (n - 1) / 2;
  var cov = 0.0;
  var den = 0.0;
  for (var i = 0; i < n; i++) {
    cov += (i - xMean) * (observed[i].volume - mean);
    den += (i - xMean) * (i - xMean);
  }
  final trend = mean > 0 && den > 0 ? cov / den / mean * 100 : null;
  final direction = trend == null
      ? null
      : trend.abs() < stableTrendPct
      ? TrendDirection.stable
      : trend > 0
      ? TrendDirection.up
      : TrendDirection.down;

  final tally = List<int>.filled(168, 0);
  for (var i = firstIdx; i < weeks; i++) {
    final ranked =
        [
          for (var c = 0; c < 168; c++)
            if (cellCounts[i][c] > 0) c,
        ]..sort((a, b) {
          final by = cellCounts[i][b].compareTo(cellCounts[i][a]);
          return by != 0 ? by : a.compareTo(b);
        });
    for (final c in ranked.take(topCells)) {
      tally[c]++;
    }
  }
  final recurring = [
    for (var c = 0; c < 168; c++)
      if (tally[c] > 0 && tally[c] * 100 >= recurrenceMinPct * n)
        RecurringCell(
          weekday: c ~/ 24,
          hour: c % 24,
          weeks: tally[c],
          observedWeeks: n,
        ),
  ]..sort((a, b) => b.weeks.compareTo(a.weeks));
  return SeasonalityReport(
    weeks: observed,
    recurring: recurring,
    trendPct: trend,
    direction: direction,
  );
}

class StaffingReport {
  const StaffingReport({required this.grid, required this.seasonality});

  final StaffingGrid grid;
  final SeasonalityReport seasonality;

  bool get hasData => grid.hasArrivals || seasonality.weeks.isNotEmpty;
}

StaffingReport buildStaffingReport(
  Iterable<HistoryEntry> entries, {
  required Iterable<HistoryEntry> seasonEntries,
  required DateTime now,
  Set<String> ownerUids = const {},
  double occupancy = defaultTargetOccupancy,
}) => StaffingReport(
  grid: computeStaffingGrid(
    entries,
    ownerUids: ownerUids,
    occupancy: occupancy,
  ),
  seasonality: computeSeasonality(seasonEntries, now: now),
);
