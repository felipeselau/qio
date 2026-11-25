import '../models/history_entry.dart';
import '../models/queue_goals.dart';
import 'abandonment_metrics.dart' show maxPlausibleWait;
import 'sp_time.dart';

const int defaultGoalMinSamples = 5;

class GoalQueueInput {
  const GoalQueueInput(this.goals, this.entries);

  final QueueGoals goals;
  final List<HistoryEntry> entries;
}

class GoalBucket {
  const GoalBucket({
    required this.total,
    required this.ok,
    required this.targetSum,
  });

  static const empty = GoalBucket(total: 0, ok: 0, targetSum: 0);

  final int total;
  final int ok;
  final int targetSum;

  int get violations => total - ok;

  double? get pct => total == 0 ? null : ok / total;

  int? get pctFloor => total == 0 ? null : ok * 100 ~/ total;

  double? get targetPct => total == 0 ? null : targetSum / total;

  bool get met => total > 0 && ok * 100 >= targetSum;
}

class GoalDay {
  const GoalDay(this.day, this.bucket);

  final DateTime day;
  final GoalBucket bucket;
}

class GoalHour {
  const GoalHour(this.hour, this.bucket);

  final int hour;
  final GoalBucket bucket;
}

class GoalIndicator {
  const GoalIndicator({
    required this.overall,
    required this.days,
    required this.hours,
    required this.missedDays,
    required this.missedHours,
    required this.queues,
    required this.configured,
    this.worstOverMin,
    this.worstDay,
  });

  static const empty = GoalIndicator(
    overall: GoalBucket.empty,
    days: [],
    hours: [],
    missedDays: [],
    missedHours: [],
    queues: 0,
    configured: 0,
  );

  final GoalBucket overall;
  final List<GoalDay> days;
  final List<GoalHour> hours;
  final List<GoalDay> missedDays;
  final List<GoalHour> missedHours;
  final int queues;
  final int configured;
  final double? worstOverMin;
  final DateTime? worstDay;

  bool get hasData => overall.total > 0;

  bool reliable(int minSamples) => overall.total >= minSamples;
}

class GoalReport {
  const GoalReport({
    required this.wait,
    required this.service,
    required this.queuesWithGoals,
  });

  static const empty = GoalReport(
    wait: GoalIndicator.empty,
    service: GoalIndicator.empty,
    queuesWithGoals: 0,
  );

  final GoalIndicator wait;
  final GoalIndicator service;
  final int queuesWithGoals;

  bool get hasGoals => queuesWithGoals > 0;

  bool get hasData => wait.hasData || service.hasData;
}

class _Acc {
  int total = 0;
  int ok = 0;
  int targetSum = 0;

  void add(bool compliant, int target) {
    total++;
    if (compliant) ok++;
    targetSum += target;
  }

  GoalBucket get bucket =>
      GoalBucket(total: total, ok: ok, targetSum: targetSum);
}

class _Sample {
  const _Sample(this.at, this.value, this.limit, this.target);

  final DateTime at;
  final double value;
  final int limit;
  final int target;

  bool get compliant => value <= limit;
}

List<_Sample> _waitSamples(GoalQueueInput q) {
  final limit = q.goals.maxWaitMin;
  if (limit == null) return const [];
  final target = q.goals.effectiveTargetPct;
  final out = <_Sample>[];
  for (final e in q.entries) {
    if (e.joinedAt.millisecondsSinceEpoch == 0) continue;
    final Duration? d;
    if (e.isServed || e.isNoShow) {
      d = e.wait;
    } else if (e.isLeft && !e.isSystemRemoved) {
      d = e.finishedAt?.difference(e.joinedAt);
    } else {
      continue;
    }
    if (d == null || d.isNegative || d > maxPlausibleWait) continue;
    final min = d.inMilliseconds / 60000;
    if (e.isLeft && min <= limit) continue;
    out.add(_Sample(e.joinedAt, min, limit, target));
  }
  return out;
}

List<_Sample> _serviceSamples(GoalQueueInput q) {
  final limit = q.goals.maxServiceMin;
  if (limit == null) return const [];
  final target = q.goals.effectiveTargetPct;
  final out = <_Sample>[];
  for (final e in q.entries) {
    if (!e.isServed) continue;
    final d = e.service;
    final called = e.calledAt;
    if (d == null || called == null || d.isNegative) continue;
    out.add(_Sample(called, d.inMilliseconds / 60000, limit, target));
  }
  return out;
}

GoalIndicator _indicator(
  List<List<_Sample>> perQueue,
  int configured,
  int minSamples,
) {
  final overall = _Acc();
  final days = <DateTime, _Acc>{};
  final hours = <int, _Acc>{};
  double? worst;
  DateTime? worstDay;
  var queues = 0;
  for (final samples in perQueue) {
    if (samples.isEmpty) continue;
    queues++;
    for (final s in samples) {
      final ok = s.compliant;
      overall.add(ok, s.target);
      days.putIfAbsent(spDay(s.at), _Acc.new).add(ok, s.target);
      hours.putIfAbsent(spHour(s.at), _Acc.new).add(ok, s.target);
      final over = s.value - s.limit;
      if (over > 0 && (worst == null || over > worst)) {
        worst = over;
        worstDay = spDay(s.at);
      }
    }
  }
  final dayList = [
    for (final k in days.keys.toList()..sort()) GoalDay(k, days[k]!.bucket),
  ];
  final hourList = [
    for (final k in hours.keys.toList()..sort()) GoalHour(k, hours[k]!.bucket),
  ];
  return GoalIndicator(
    overall: overall.bucket,
    days: dayList,
    hours: hourList,
    missedDays: [
      for (final d in dayList)
        if (d.bucket.total >= minSamples && !d.bucket.met) d,
    ],
    missedHours: [
      for (final h in hourList)
        if (h.bucket.total >= minSamples && !h.bucket.met) h,
    ],
    queues: queues,
    configured: configured,
    worstOverMin: worst,
    worstDay: worstDay,
  );
}

GoalReport computeGoalReport(
  List<GoalQueueInput> inputs, {
  int minSamples = defaultGoalMinSamples,
}) {
  final withGoals = inputs.where((i) => i.goals.hasGoal).toList();
  if (withGoals.isEmpty) return GoalReport.empty;
  return GoalReport(
    wait: _indicator(
      [for (final q in withGoals) _waitSamples(q)],
      withGoals.where((q) => q.goals.maxWaitMin != null).length,
      minSamples,
    ),
    service: _indicator(
      [for (final q in withGoals) _serviceSamples(q)],
      withGoals.where((q) => q.goals.maxServiceMin != null).length,
      minSamples,
    ),
    queuesWithGoals: withGoals.length,
  );
}
