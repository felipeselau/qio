import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/services/abandonment_metrics.dart';

DateTime t(int day, int h, [int m = 0]) => DateTime.utc(2026, 5, day, h, m);

int _n = 0;

HistoryEntry served(int waitMin, {DateTime? joined, String result = 'served'}) {
  final j = joined ?? t(10, 13);
  final c = j.add(Duration(minutes: waitMin));
  return HistoryEntry(
    id: 'e${_n++}',
    ticket: 1,
    name: 'x',
    result: result,
    joinedAt: j,
    calledAt: c,
    finishedAt: c.add(const Duration(minutes: 5)),
  );
}

HistoryEntry withEstimate(HistoryEntry e, int? estimateMin) => HistoryEntry(
  id: e.id,
  ticket: e.ticket,
  name: e.name,
  result: e.result,
  joinedAt: e.joinedAt,
  calledAt: e.calledAt,
  finishedAt: e.finishedAt,
  reason: e.reason,
  estimateMin: estimateMin,
);

HistoryEntry left(int waitMin, {DateTime? joined, String? reason}) {
  final j = joined ?? t(10, 13);
  return HistoryEntry(
    id: 'e${_n++}',
    ticket: 1,
    name: 'x',
    result: 'left',
    joinedAt: j,
    finishedAt: j.add(Duration(minutes: waitMin)),
    reason: reason,
  );
}

List<HistoryEntry> dataset() => [
  for (final w in [2, 2, 2, 7, 7, 7, 12, 12, 12, 25]) served(w),
  served(6, result: 'no_show'),
  for (final w in [3, 8, 8, 15, 15, 30, 30, 50]) left(w),
];

void main() {
  group('abandonmentByWait', () {
    test('vazio', () {
      final bands = abandonmentByWait([]);
      expect(bands.length, 5);
      expect(bands.every((b) => b.atRisk == 0 && b.rate == null), isTrue);
      expect(findInflection(bands), isNull);
    });

    test('taxa = desistencias na faixa / quem atingiu a faixa', () {
      final b = abandonmentByWait(dataset());
      expect(b.map((x) => x.startMin), [0, 5, 10, 20, 40]);
      expect(b.last.endMin, isNull);
      expect(b[0].atRisk, 19);
      expect(b[0].left, 1);
      expect(b[0].rate, closeTo(1 / 19, 1e-9));
      expect(b[1].atRisk, 15);
      expect(b[1].left, 2);
      expect(b[1].rate, closeTo(2 / 15, 1e-9));
      expect(b[2].atRisk, 9);
      expect(b[2].left, 2);
      expect(b[2].rate, closeTo(2 / 9, 1e-9));
      expect(b[0].hazardPerMin, closeTo(1 / 19 / 5, 1e-9));
      expect(b[1].hazardPerMin, closeTo(2 / 15 / 5, 1e-9));
      expect(b[2].hazardPerMin, closeTo(2 / 9 / 10, 1e-9));
      expect(b[3].hazardPerMin, isNull);
      expect(b[3].atRisk, 4);
      expect(b[3].left, 2);
      expect(b[3].rate, isNull);
      expect(b[4].atRisk, 1);
      expect(b[4].left, 1);
      expect(b[4].rate, isNull);
    });

    test('left de sistema e entradas incompletas ficam de fora', () {
      final extra = [
        left(50, reason: 'expired'),
        left(50, reason: 'closed'),
        HistoryEntry(
          id: 'n1',
          ticket: 1,
          name: 'x',
          result: 'served',
          joinedAt: t(10, 13),
        ),
        HistoryEntry(
          id: 'n2',
          ticket: 1,
          name: 'x',
          result: 'left',
          joinedAt: t(10, 13),
        ),
      ];
      final a = abandonmentByWait(dataset());
      final b = abandonmentByWait([...dataset(), ...extra]);
      for (var i = 0; i < a.length; i++) {
        expect(b[i].atRisk, a[i].atRisk);
        expect(b[i].left, a[i].left);
      }
    });

    test('faixas configuraveis', () {
      final b = abandonmentByWait(dataset(), edges: [10], minSamples: 1);
      expect(b.length, 2);
      expect(b[1].startMin, 10);
      expect(b[1].atRisk, 9);
      expect(b[1].left, 5);
    });
  });

  group('filtros e validacao', () {
    test('joinedAt na epoca 0 e esperas acima de 24 h sao descartados', () {
      final bad = [
        left(10, joined: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)),
        left(25 * 60),
        served(30 * 60),
      ];
      expect(abandonmentSamples(bad), isEmpty);
      expect(abandonmentSamples([left(24 * 60)]).length, 1);
    });

    test('left sem finishedAt e served sem calledAt sao ignorados', () {
      final e = [
        HistoryEntry(
          id: 'a',
          ticket: 1,
          name: 'x',
          result: 'left',
          joinedAt: t(10, 13),
        ),
        HistoryEntry(
          id: 'b',
          ticket: 1,
          name: 'x',
          result: 'no_show',
          joinedAt: t(10, 13),
          finishedAt: t(10, 14),
        ),
      ];
      expect(abandonmentSamples(e), isEmpty);
    });

    test('edges invalidas', () {
      expect(
        () => abandonmentByWait([], edges: [10, 5]),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => abandonmentByWait([], edges: [5, 5]),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => abandonmentByWait([], edges: [0, 5]),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => abandonmentByWait([], edges: [-1]),
        throwsA(isA<AssertionError>()),
      );
      expect(abandonmentByWait([], edges: []).length, 1);
    });
  });

  group('findInflection', () {
    test('primeira faixa acima do limiar', () {
      final i = findInflection(abandonmentByWait(dataset()));
      expect(i?.startMin, 5);
    });

    test('compara por taxa a cada 10 min, nao pela proporcao bruta', () {
      final b = abandonmentByWait(dataset());
      expect(b[1].rate! < b[2].rate!, isTrue);
      expect(b[1].ratePer10Min! > b[2].ratePer10Min!, isTrue);
      expect(findInflection(b, threshold: 0.25)?.startMin, 5);
      expect(findInflection(b, threshold: 0.27), isNull);
    });

    test('faixa aberta usa a maior espera observada como largura', () {
      final b = abandonmentByWait(dataset(), minSamples: 1);
      expect(b[4].hazardPerMin, closeTo(1 / 10, 1e-9));
      expect(b[4].ratePer10Min, closeTo(1, 1e-9));
    });

    test('limiar estrito e minSamples por faixa', () {
      final low = abandonmentByWait(dataset(), minSamples: 1);
      expect(findInflection(low, threshold: 0.5)?.startMin, 40);
      expect(findInflection(low, threshold: 1), isNull);
      final strict = abandonmentByWait(dataset());
      expect(findInflection(strict, threshold: 0.5), isNull);
    });
  });

  group('abandonmentByHour', () {
    test('vazio', () {
      final h = abandonmentByHour([]);
      expect(h.length, 24);
      expect(
        h.every((x) => x.total == 0 && x.rate == null && x.avgWaitMin == null),
        isTrue,
      );
    });

    test('taxa, contagem e espera media por hora de chegada em SP', () {
      final j10 = t(10, 13);
      final late = t(11, 2, 30);
      final j15 = t(10, 18);
      final h = abandonmentByHour([
        for (var i = 0; i < 4; i++) served(20, joined: j10),
        left(10, joined: j10),
        left(10, joined: j10),
        for (var i = 0; i < 5; i++) served(1, joined: late),
        left(10, joined: j15),
        left(20, joined: j15),
        left(40, joined: j10, reason: 'expired'),
      ]);
      expect(h[10].total, 6);
      expect(h[10].left, 2);
      expect(h[10].rate, closeTo(1 / 3, 1e-9));
      expect(h[10].avgWaitMin, closeTo(100 / 6, 1e-9));
      expect(h[23].total, 5);
      expect(h[23].rate, 0);
      expect(h[23].avgWaitMin, closeTo(1, 1e-9));
      expect(h[15].total, 2);
      expect(h[15].left, 2);
      expect(h[15].rate, isNull);
      expect(h[15].avgWaitMin, closeTo(15, 1e-9));
    });

    test('virada do dia', () {
      final h = abandonmentByHour([
        left(5, joined: t(11, 2, 59)),
        left(5, joined: t(11, 3)),
      ], minSamples: 1);
      expect(h[23].total, 1);
      expect(h[0].total, 1);
      expect(h[0].rate, 1);
    });
  });

  group('capacitySignalHours', () {
    List<HourAbandonment> hours() => abandonmentByHour([
      for (var i = 0; i < 4; i++) served(20, joined: t(10, 13)),
      left(10, joined: t(10, 13)),
      left(10, joined: t(10, 13)),
      for (var i = 0; i < 5; i++) served(1, joined: t(11, 2, 30)),
      left(10, joined: t(10, 18)),
      left(20, joined: t(10, 18)),
    ]);

    test('espera alta e desistencia alta', () {
      expect(capacitySignalHours(hours()), [10]);
    });

    test('limiares configuraveis', () {
      expect(capacitySignalHours(hours(), waitThresholdMin: 20), isEmpty);
      expect(capacitySignalHours(hours(), rateThreshold: 0.5), isEmpty);
      expect(
        capacitySignalHours(hours(), waitThresholdMin: 16, rateThreshold: 0.3),
        [10],
      );
    });

    test('vazio', () {
      expect(capacitySignalHours(abandonmentByHour([])), isEmpty);
    });
  });

  group('abandonmentByEstimate', () {
    test('vazio', () {
      final b = abandonmentByEstimate([]);
      expect(b.map((x) => x.startMin), [0, 5, 10, 20, 40]);
      expect(b.last.endMin, isNull);
      expect(b.every((x) => x.total == 0 && x.rate == null), isTrue);
    });

    test('agrupa pela estimativa mostrada e ignora quem nao tem campo', () {
      final b = abandonmentByEstimate([
        for (var i = 0; i < 4; i++) withEstimate(served(3), 3),
        withEstimate(left(4), 4),
        for (var i = 0; i < 3; i++) withEstimate(served(8), 5),
        for (var i = 0; i < 3; i++) withEstimate(left(8), 9),
        for (var i = 0; i < 5; i++) withEstimate(served(8), 45),
        served(2),
        left(2),
        withEstimate(left(5, reason: 'expired'), 3),
        withEstimate(left(5, reason: 'closed'), 3),
      ]);
      expect(b[0].total, 5);
      expect(b[0].left, 1);
      expect(b[0].rate, closeTo(0.2, 1e-9));
      expect(b[1].total, 6);
      expect(b[1].left, 3);
      expect(b[1].rate, closeTo(0.5, 1e-9));
      expect(b[2].total, 0);
      expect(b[2].rate, isNull);
      expect(b[4].total, 5);
      expect(b[4].left, 0);
      expect(b[4].rate, 0);
    });

    test('abaixo da amostra minima a taxa e nula', () {
      final b = abandonmentByEstimate([
        withEstimate(left(5), 12),
        withEstimate(served(5), 12),
      ]);
      expect(b[2].total, 2);
      expect(b[2].left, 1);
      expect(b[2].rate, isNull);
      expect(
        abandonmentByEstimate([
          withEstimate(left(5), 12),
        ], minSamples: 1)[2].rate,
        1,
      );
    });

    test('borda pertence a faixa seguinte', () {
      final b = abandonmentByEstimate([
        withEstimate(served(1), 5),
        withEstimate(served(1), 4),
        withEstimate(served(1), 40),
      ], minSamples: 1);
      expect(b[0].total, 1);
      expect(b[1].total, 1);
      expect(b[4].total, 1);
    });
  });

  group('estimateAccuracy', () {
    test('vazio', () {
      final a = estimateAccuracy([]);
      expect(a.samples, 0);
      expect(a.meanErrorMin, isNull);
    });

    test('erro medio = espera real - estimativa', () {
      final a = estimateAccuracy([
        withEstimate(served(10), 5),
        withEstimate(served(10), 15),
        withEstimate(served(20), 10),
        withEstimate(served(6, result: 'no_show'), 6),
        withEstimate(served(2), 4),
        withEstimate(left(30), 5),
        served(40),
        withEstimate(served(40), null),
      ]);
      expect(a.samples, 5);
      expect(a.meanErrorMin, closeTo((5 - 5 + 10 + 0 - 2) / 5, 1e-9));
      expect(a.meanAbsErrorMin, closeTo((5 + 5 + 10 + 0 + 2) / 5, 1e-9));
    });

    test('amostra insuficiente', () {
      final a = estimateAccuracy([withEstimate(served(10), 5)]);
      expect(a.samples, 1);
      expect(a.meanErrorMin, isNull);
      expect(
        estimateAccuracy([
          withEstimate(served(10), 5),
        ], minSamples: 1).meanErrorMin,
        5,
      );
    });
  });

  group('faixa estreita e joinedAt na epoca 0', () {
    HistoryEntry leftAt(double waitMin) {
      final j = t(10, 13);
      return HistoryEntry(
        id: 'e${_n++}',
        ticket: 1,
        name: 'x',
        result: 'left',
        joinedAt: j,
        finishedAt: j.add(Duration(milliseconds: (waitMin * 60000).round())),
      );
    }

    test('5 pessoas entre 40,0 e 40,5 min nao passam de 100%', () {
      final b = abandonmentByWait([
        for (final w in [40.0, 40.1, 40.2, 40.3, 40.5]) leftAt(w),
      ]);
      final open = b.last;
      expect(open.atRisk, 5);
      expect(open.left, 5);
      expect(open.rate, 1);
      expect(open.hazardPerMin, closeTo(1 / minBandWidthMin, 1e-9));
      expect(open.ratePer10Min, 1);
      expect(findInflection(b)!.startMin, 40);
    });

    test('faixa de largura normal segue sem limite aplicado', () {
      final b = abandonmentByWait(dataset());
      expect(b[1].ratePer10Min, closeTo(2 / 15 / 5 * 10, 1e-9));
    });

    test('estimativa e precisao ignoram joinedAt na epoca 0', () {
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      HistoryEntry broken() => HistoryEntry(
        id: 'b${_n++}',
        ticket: 1,
        name: 'x',
        result: 'served',
        joinedAt: epoch,
        calledAt: t(10, 13),
        finishedAt: t(10, 13, 5),
        estimateMin: 5,
      );
      final entries = [
        for (var i = 0; i < 5; i++) withEstimate(served(10), 5),
        broken(),
        broken(),
      ];
      expect(abandonmentByEstimate(entries)[1].total, 5);
      expect(estimateAccuracy(entries).samples, 5);
    });
  });
}
