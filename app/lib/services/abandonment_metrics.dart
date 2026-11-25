import 'dart:math' as math;

import '../models/history_entry.dart';
import 'sp_time.dart';

const List<int> defaultWaitBandEdges = [5, 10, 20, 40];
const int defaultAbandonMinSamples = 5;
const double defaultInflectionThreshold = 0.2;
const double defaultWaitThresholdMin = 15;
const double inflectionWindowMin = 10;
const double minBandWidthMin = 5;
const Duration maxPlausibleWait = Duration(hours: 24);

class WaitSample {
  const WaitSample({
    required this.joinedAt,
    required this.waitMin,
    required this.left,
  });

  final DateTime joinedAt;
  final double waitMin;
  final bool left;
}

List<WaitSample> abandonmentSamples(Iterable<HistoryEntry> entries) {
  final out = <WaitSample>[];
  for (final e in entries) {
    if (e.isSystemRemoved) continue;
    if (e.joinedAt.millisecondsSinceEpoch == 0) continue;
    final Duration? d;
    if (e.isLeft) {
      d = e.finishedAt?.difference(e.joinedAt);
    } else if (e.isServed || e.isNoShow) {
      d = e.wait;
    } else {
      continue;
    }
    if (d == null || d.isNegative || d > maxPlausibleWait) continue;
    out.add(
      WaitSample(
        joinedAt: e.joinedAt,
        waitMin: d.inMilliseconds / 60000,
        left: e.isLeft,
      ),
    );
  }
  return out;
}

class AbandonmentBand {
  const AbandonmentBand({
    required this.startMin,
    this.endMin,
    required this.atRisk,
    required this.left,
    this.rate,
    this.hazardPerMin,
  });

  final int startMin;
  final int? endMin;
  final int atRisk;
  final int left;
  final double? rate;
  final double? hazardPerMin;

  double? get ratePer10Min => hazardPerMin == null
      ? null
      : math.min(1.0, hazardPerMin! * inflectionWindowMin);
}

List<AbandonmentBand> abandonmentByWait(
  Iterable<HistoryEntry> entries, {
  List<int> edges = defaultWaitBandEdges,
  int minSamples = defaultAbandonMinSamples,
}) {
  assert(
    edges.every((e) => e > 0) &&
        [
          for (var i = 1; i < edges.length; i++) edges[i] > edges[i - 1],
        ].every((ok) => ok),
    'edges must be positive and strictly increasing',
  );
  final samples = abandonmentSamples(entries);
  final starts = [0, ...edges];
  final out = <AbandonmentBand>[];
  for (var i = 0; i < starts.length; i++) {
    final start = starts[i];
    final end = i + 1 < starts.length ? starts[i + 1] : null;
    var atRisk = 0;
    var left = 0;
    var maxWait = 0.0;
    for (final s in samples) {
      if (s.waitMin < start) continue;
      atRisk++;
      if (s.waitMin > maxWait) maxWait = s.waitMin;
      if (s.left && (end == null || s.waitMin < end)) left++;
    }
    final width = end == null ? maxWait - start : (end - start).toDouble();
    final rate = atRisk >= minSamples && atRisk > 0 ? left / atRisk : null;
    out.add(
      AbandonmentBand(
        startMin: start,
        endMin: end,
        atRisk: atRisk,
        left: left,
        rate: rate,
        hazardPerMin: rate != null
            ? rate / math.max(width, minBandWidthMin)
            : null,
      ),
    );
  }
  return out;
}

AbandonmentBand? findInflection(
  List<AbandonmentBand> bands, {
  double threshold = defaultInflectionThreshold,
}) {
  for (final b in bands) {
    final r = b.ratePer10Min;
    if (r != null && r > threshold) return b;
  }
  return null;
}

class HourAbandonment {
  const HourAbandonment({
    required this.hour,
    required this.total,
    required this.left,
    this.rate,
    this.avgWaitMin,
  });

  final int hour;
  final int total;
  final int left;
  final double? rate;
  final double? avgWaitMin;
}

List<HourAbandonment> abandonmentByHour(
  Iterable<HistoryEntry> entries, {
  int minSamples = defaultAbandonMinSamples,
}) {
  final totals = List<int>.filled(24, 0);
  final lefts = List<int>.filled(24, 0);
  final waits = List<double>.filled(24, 0);
  for (final s in abandonmentSamples(entries)) {
    final h = spHour(s.joinedAt);
    totals[h]++;
    waits[h] += s.waitMin;
    if (s.left) lefts[h]++;
  }
  return [
    for (var h = 0; h < 24; h++)
      HourAbandonment(
        hour: h,
        total: totals[h],
        left: lefts[h],
        rate: totals[h] >= minSamples && totals[h] > 0
            ? lefts[h] / totals[h]
            : null,
        avgWaitMin: totals[h] > 0 ? waits[h] / totals[h] : null,
      ),
  ];
}

List<int> capacitySignalHours(
  List<HourAbandonment> hours, {
  double waitThresholdMin = defaultWaitThresholdMin,
  double rateThreshold = defaultInflectionThreshold,
}) {
  return [
    for (final h in hours)
      if (h.rate != null &&
          h.avgWaitMin != null &&
          h.avgWaitMin! >= waitThresholdMin &&
          h.rate! >= rateThreshold)
        h.hour,
  ];
}

const List<int> defaultEstimateBandEdges = [5, 10, 20, 40];

class EstimateBand {
  const EstimateBand({
    required this.startMin,
    this.endMin,
    required this.total,
    required this.left,
    this.rate,
  });

  final int startMin;
  final int? endMin;
  final int total;
  final int left;
  final double? rate;
}

List<EstimateBand> abandonmentByEstimate(
  Iterable<HistoryEntry> entries, {
  List<int> edges = defaultEstimateBandEdges,
  int minSamples = defaultAbandonMinSamples,
}) {
  assert(
    edges.every((e) => e > 0) &&
        [
          for (var i = 1; i < edges.length; i++) edges[i] > edges[i - 1],
        ].every((ok) => ok),
    'edges must be positive and strictly increasing',
  );
  final starts = [0, ...edges];
  final totals = List<int>.filled(starts.length, 0);
  final lefts = List<int>.filled(starts.length, 0);
  for (final e in entries) {
    final est = e.estimateMin;
    if (est == null || est < 0 || e.isSystemRemoved) continue;
    if (e.joinedAt.millisecondsSinceEpoch == 0) continue;
    if (!e.isServed && !e.isNoShow && !e.isLeft) continue;
    var i = starts.length - 1;
    while (i > 0 && est < starts[i]) {
      i--;
    }
    totals[i]++;
    if (e.isLeft) lefts[i]++;
  }
  return [
    for (var i = 0; i < starts.length; i++)
      EstimateBand(
        startMin: starts[i],
        endMin: i + 1 < starts.length ? starts[i + 1] : null,
        total: totals[i],
        left: lefts[i],
        rate: totals[i] >= minSamples && totals[i] > 0
            ? lefts[i] / totals[i]
            : null,
      ),
  ];
}

class EstimateAccuracy {
  const EstimateAccuracy({
    required this.samples,
    this.meanErrorMin,
    this.meanAbsErrorMin,
  });

  final int samples;
  final double? meanErrorMin;
  final double? meanAbsErrorMin;
}

EstimateAccuracy estimateAccuracy(
  Iterable<HistoryEntry> entries, {
  int minSamples = defaultAbandonMinSamples,
}) {
  var n = 0;
  var sum = 0.0;
  var abs = 0.0;
  for (final e in entries) {
    final est = e.estimateMin;
    if (est == null || est < 0) continue;
    if (e.joinedAt.millisecondsSinceEpoch == 0) continue;
    if (!e.isServed && !e.isNoShow) continue;
    final w = e.wait;
    if (w == null || w.isNegative || w > maxPlausibleWait) continue;
    final err = w.inMilliseconds / 60000 - est;
    n++;
    sum += err;
    abs += err.abs();
  }
  return EstimateAccuracy(
    samples: n,
    meanErrorMin: n >= minSamples && n > 0 ? sum / n : null,
    meanAbsErrorMin: n >= minSamples && n > 0 ? abs / n : null,
  );
}

class AbandonmentReport {
  const AbandonmentReport({
    required this.samples,
    required this.waitBands,
    required this.inflection,
    required this.estimateBands,
    required this.accuracy,
    required this.hours,
    required this.capacityHours,
  });

  final int samples;
  final List<AbandonmentBand> waitBands;
  final AbandonmentBand? inflection;
  final List<EstimateBand> estimateBands;
  final EstimateAccuracy accuracy;
  final List<HourAbandonment> hours;
  final List<int> capacityHours;

  bool get hasData => samples > 0;
  bool get hasEstimates => estimateBands.any((b) => b.total > 0);
  bool get hasWaitRates => waitBands.any((b) => b.rate != null);
  bool get hasHourRates => hours.any((h) => h.total > 0);
}

AbandonmentReport buildAbandonmentReport(List<HistoryEntry> entries) {
  final waitBands = abandonmentByWait(entries);
  final hours = abandonmentByHour(entries);
  return AbandonmentReport(
    samples: abandonmentSamples(entries).length,
    waitBands: waitBands,
    inflection: findInflection(waitBands),
    estimateBands: abandonmentByEstimate(entries),
    accuracy: estimateAccuracy(entries),
    hours: hours,
    capacityHours: capacitySignalHours(hours),
  );
}
