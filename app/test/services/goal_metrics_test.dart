import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/models/queue_goals.dart';
import 'package:qio_app/services/goal_metrics.dart';
import 'package:qio_app/services/goal_risk.dart';

int _n = 0;

HistoryEntry served(
  DateTime joined,
  double waitMin,
  double serviceMin, {
  String result = 'served',
}) {
  final called = joined.add(Duration(seconds: (waitMin * 60).round()));
  return HistoryEntry(
    id: 'e${_n++}',
    ticket: 1,
    name: 'x',
    result: result,
    joinedAt: joined,
    calledAt: called,
    finishedAt: called.add(Duration(seconds: (serviceMin * 60).round())),
  );
}

HistoryEntry left(DateTime joined, double waitMin, {String? reason}) =>
    HistoryEntry(
      id: 'e${_n++}',
      ticket: 1,
      name: 'x',
      result: 'left',
      joinedAt: joined,
      finishedAt: joined.add(Duration(seconds: (waitMin * 60).round())),
      reason: reason,
    );

final d1 = DateTime.utc(2026, 5, 10, 15);

GoalQueueInput q(
  List<HistoryEntry> e, {
  int? wait,
  int? service,
  int? target,
}) => GoalQueueInput(
  QueueGoals(maxWaitMin: wait, maxServiceMin: service, targetPct: target),
  e,
);

void main() {
  group('QueueGoals', () {
    test('fromMap tolerante', () {
      expect(QueueGoals.fromMap('x'), isNull);
      final g = QueueGoals.fromMap({
        'maxWaitMin': 15,
        'maxServiceMin': '10',
        'targetPct': 30,
      })!;
      expect(g.maxWaitMin, 15);
      expect(g.maxServiceMin, isNull);
      expect(g.targetPct, isNull);
      expect(g.effectiveTargetPct, 80);
      expect(QueueGoals.fromMap({'maxWaitMin': 15.5})!.maxWaitMin, isNull);
      expect(QueueGoals.fromMap({'maxWaitMin': 241})!.maxWaitMin, isNull);
    });

    test('validate e toMap', () {
      expect(const QueueGoals().validate(), GoalsError.noGoal);
      expect(const QueueGoals(targetPct: 90).validate(), GoalsError.noGoal);
      expect(const QueueGoals(maxWaitMin: 0).validate(), GoalsError.maxWait);
      expect(
        const QueueGoals(maxServiceMin: 241).validate(),
        GoalsError.maxService,
      );
      expect(
        const QueueGoals(maxWaitMin: 5, targetPct: 49).validate(),
        GoalsError.targetPct,
      );
      expect(
        const QueueGoals(maxWaitMin: 5, targetPct: 100).validate(),
        isNull,
      );
      expect(const QueueGoals(maxServiceMin: 8, targetPct: 70).toMap(), {
        'maxServiceMin': 8,
        'targetPct': 70,
      });
    });
  });

  group('risco em tempo real', () {
    test('estimativa usa auto, depois manual, depois 10', () {
      expect(effectiveAvgServiceMin(2.5, 7), 2.5);
      expect(effectiveAvgServiceMin(null, 7), 7);
      expect(effectiveAvgServiceMin(0, null), 10);
      expect(effectiveAvgServiceMin(double.nan, -1), 10);
      expect(estimatedWaitMin(4, auto: 2.5, manual: 7), 10);
      expect(estimatedWaitMin(3, manual: 7), 21);
      expect(estimatedWaitMin(0, manual: 7), 0);
      expect(estimatedWaitMin(2), 20);
    });

    test('risco só acima da meta, estritamente', () {
      const g = QueueGoals(maxWaitMin: 10);
      expect(waitGoalAtRisk(10, g), isFalse);
      expect(waitGoalAtRisk(11, g), isTrue);
      expect(waitGoalAtRisk(99, const QueueGoals(maxServiceMin: 5)), isFalse);
      expect(waitGoalAtRisk(99, null), isFalse);
    });
  });

  group('espera', () {
    test('percentual, meta atingida e maior violação', () {
      final r = computeGoalReport([
        q([
          for (final w in [5.0, 8.0, 10.0, 11.0, 20.0]) served(d1, w, 1),
        ], wait: 10),
      ]);
      expect(r.hasGoals, isTrue);
      expect(r.wait.overall.total, 5);
      expect(r.wait.overall.ok, 3);
      expect(r.wait.overall.pct, closeTo(0.6, 1e-9));
      expect(r.wait.overall.targetPct, 80);
      expect(r.wait.overall.met, isFalse);
      expect(r.wait.worstOverMin, closeTo(10, 1e-9));
      expect(r.wait.worstDay, DateTime.utc(2026, 5, 10));
      expect(r.service.hasData, isFalse);
    });

    test('exatamente na meta cumpre e alvo igual ao percentual atinge', () {
      final r = computeGoalReport([
        q(
          [
            for (final w in [1.0, 2.0, 3.0, 4.0, 11.0]) served(d1, w, 1),
          ],
          wait: 10,
          target: 80,
        ),
      ]);
      expect(r.wait.overall.ok, 4);
      expect(r.wait.overall.met, isTrue);
    });

    test('left só conta quando esperou mais que a meta', () {
      final r = computeGoalReport([
        q([
          served(d1, 3, 1),
          served(d1, 4, 1, result: 'no_show'),
          left(d1, 15),
          left(d1, 7),
          left(d1, 10),
          left(d1, 30, reason: 'expired'),
          left(d1, 30, reason: 'closed'),
        ], wait: 10),
      ]);
      expect(r.wait.overall.total, 3);
      expect(r.wait.overall.ok, 2);
      expect(r.wait.worstOverMin, closeTo(5, 1e-9));
    });

    test('descarta amostras inválidas', () {
      final bad = HistoryEntry(
        id: 'z',
        ticket: 1,
        name: 'x',
        result: 'served',
        joinedAt: DateTime.fromMillisecondsSinceEpoch(0),
        calledAt: d1,
        finishedAt: d1,
      );
      final negative = HistoryEntry(
        id: 'n',
        ticket: 1,
        name: 'x',
        result: 'served',
        joinedAt: d1,
        calledAt: d1.subtract(const Duration(minutes: 5)),
        finishedAt: d1,
      );
      final noCall = HistoryEntry(
        id: 'c',
        ticket: 1,
        name: 'x',
        result: 'served',
        joinedAt: d1,
      );
      final huge = served(d1, 60 * 25, 1);
      final r = computeGoalReport([
        q([bad, negative, noCall, huge], wait: 10),
      ]);
      expect(r.wait.hasData, isFalse);
      expect(r.wait.worstOverMin, isNull);
    });
  });

  group('atendimento', () {
    test('só served entra e compara finishedAt - calledAt', () {
      final r = computeGoalReport([
        q(
          [
            served(d1, 1, 3),
            served(d1, 1, 5),
            served(d1, 1, 6),
            served(d1, 1, 40, result: 'no_show'),
            left(d1, 50),
          ],
          service: 5,
          target: 50,
        ),
      ]);
      expect(r.service.overall.total, 3);
      expect(r.service.overall.ok, 2);
      expect(r.service.overall.met, isTrue);
      expect(r.service.worstOverMin, closeTo(1, 1e-9));
      expect(r.wait.hasData, isFalse);
    });
  });

  group('agregado com metas diferentes', () {
    test('alvo médio ponderado pelas amostras', () {
      List<HistoryEntry> okSamples(int n) => [
        for (var i = 0; i < n; i++) served(d1, 1, 1),
      ];
      final q1 = q(okSamples(4), wait: 10, target: 80);
      final q2 = q([served(d1, 30, 1)], wait: 10, target: 100);
      final r = computeGoalReport([q1, q2]);
      expect(r.queuesWithGoals, 2);
      expect(r.wait.queues, 2);
      expect(r.wait.overall.total, 5);
      expect(r.wait.overall.ok, 4);
      expect(r.wait.overall.targetPct, closeTo(84, 1e-9));
      expect(r.wait.overall.met, isFalse);
      final q3 = q([served(d1, 1, 1)], wait: 10, target: 100);
      expect(computeGoalReport([q1, q3]).wait.overall.met, isTrue);
    });

    test('fila sem meta é ignorada e conta zero filas', () {
      final r = computeGoalReport([
        q([served(d1, 99, 99)]),
        q([served(d1, 1, 1)], wait: 10),
      ]);
      expect(r.queuesWithGoals, 1);
      expect(r.wait.overall.total, 1);
      expect(
        computeGoalReport([
          q([served(d1, 1, 1)]),
        ]).hasGoals,
        isFalse,
      );
      expect(computeGoalReport(const []), same(GoalReport.empty));
    });
  });

  group('períodos não atingidos', () {
    test('dia abaixo do alvo com amostra mínima, em UTC-3', () {
      final day1 = DateTime.utc(2026, 5, 10, 15);
      final day2 = DateTime.utc(2026, 5, 11, 15);
      final day3 = DateTime.utc(2026, 5, 12, 15);
      final r = computeGoalReport([
        q([
          for (var i = 0; i < 5; i++) served(day1, 1, 1),
          for (var i = 0; i < 5; i++) served(day2, i < 2 ? 1 : 30, 1),
          for (var i = 0; i < 4; i++) served(day3, 30, 1),
        ], wait: 10),
      ]);
      expect(r.wait.days.length, 3);
      expect(r.wait.missedDays.length, 1);
      expect(r.wait.missedDays.single.day, DateTime.utc(2026, 5, 11));
      expect(r.wait.missedDays.single.bucket.ok, 2);
      expect(r.wait.missedDays.single.bucket.total, 5);
    });

    test('virada do dia usa São Paulo', () {
      final late = DateTime.utc(2026, 5, 11, 2, 30);
      final early = DateTime.utc(2026, 5, 11, 3, 30);
      final r = computeGoalReport([
        q([served(late, 1, 1), served(early, 1, 1)], wait: 10),
      ]);
      expect(r.wait.days.map((d) => d.day).toList(), [
        DateTime.utc(2026, 5, 10),
        DateTime.utc(2026, 5, 11),
      ]);
    });

    test('horas abaixo do alvo', () {
      final h12 = DateTime.utc(2026, 5, 10, 15);
      final h13 = DateTime.utc(2026, 5, 10, 16);
      final r = computeGoalReport([
        q([
          for (var i = 0; i < 5; i++) served(h12, 1, 1),
          for (var i = 0; i < 5; i++) served(h13, 30, 1),
        ], wait: 10),
      ]);
      expect(r.wait.missedHours.map((h) => h.hour).toList(), [13]);
      expect(r.wait.hours.map((h) => h.hour).toList(), [12, 13]);
    });

    test('amostra mínima é parâmetro', () {
      final r = computeGoalReport([
        q([served(d1, 30, 1)], wait: 10),
      ], minSamples: 1);
      expect(r.wait.missedDays.length, 1);
      expect(r.wait.reliable(5), isFalse);
      expect(r.wait.reliable(1), isTrue);
    });
  });
}
