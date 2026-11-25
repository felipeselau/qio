import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/services/attendant_metrics.dart';
import 'package:qio_app/services/operator_metrics.dart';
import 'package:qio_app/services/sp_time.dart';

DateTime t(int day, int h, [int m = 0]) => DateTime.utc(2026, 5, day, h, m);

int _n = 0;

HistoryEntry handled({
  required String by,
  required DateTime joined,
  required DateTime called,
  required DateTime finished,
  String result = 'served',
}) => HistoryEntry(
  id: 'e${_n++}',
  ticket: 1,
  name: 'x',
  result: result,
  joinedAt: joined,
  calledAt: called,
  finishedAt: finished,
  calledBy: by,
);

HistoryEntry svc(String by, int serviceMin) {
  final c = t(10, 12);
  return handled(
    by: by,
    joined: c,
    called: c,
    finished: c.add(Duration(minutes: serviceMin)),
  );
}

void main() {
  group('shiftOfHour', () {
    test('limites dos turnos', () {
      expect(shiftOfHour(5), Shift.night);
      expect(shiftOfHour(6), Shift.morning);
      expect(shiftOfHour(11), Shift.morning);
      expect(shiftOfHour(12), Shift.afternoon);
      expect(shiftOfHour(17), Shift.afternoon);
      expect(shiftOfHour(18), Shift.night);
      expect(shiftOfHour(0), Shift.night);
    });
  });

  group('computeOperatorThroughput', () {
    test('vazio', () {
      expect(computeOperatorThroughput([]), isEmpty);
    });

    test('hora, dia e turno em America/Sao_Paulo', () {
      HistoryEntry f(
        DateTime fin, {
        String result = 'served',
        String by = 'a',
      }) => handled(
        by: by,
        joined: fin.subtract(const Duration(minutes: 30)),
        called: fin.subtract(const Duration(minutes: 5)),
        finished: fin,
        result: result,
      );
      final r = computeOperatorThroughput(
        [
          f(t(10, 9, 30)),
          f(t(10, 14)),
          f(t(10, 15)),
          f(t(11, 2, 30)),
          f(t(11, 3, 30)),
          f(t(10, 15), result: 'no_show'),
          f(t(10, 15), by: 'o'),
        ],
        ownerUids: {'o'},
      );
      expect(r.length, 2);
      final a = r.first;
      expect(a.attendantId, 'a');
      expect(a.total, 5);
      expect(a.byHour[6], 1);
      expect(a.byHour[11], 1);
      expect(a.byHour[12], 1);
      expect(a.byHour[23], 1);
      expect(a.byHour[0], 1);
      expect(a.byHour.reduce((x, y) => x + y), 5);
      expect(a.byDay, {
        DateTime.utc(2026, 5, 10): 4,
        DateTime.utc(2026, 5, 11): 1,
      });
      expect(a.byShift[Shift.morning], 2);
      expect(a.byShift[Shift.afternoon], 1);
      expect(a.byShift[Shift.night], 2);
      expect(r.last.isOwner, isTrue);
      expect(r.last.total, 1);
    });
  });

  group('computeOperatorRates', () {
    test('atendimentos por hora efetiva', () {
      final r = computeOperatorRates([
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 12),
          finished: t(10, 12, 10),
        ),
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 12, 20),
          finished: t(10, 12, 30),
        ),
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 13),
          finished: t(10, 13, 30),
        ),
      ]);
      expect(r.length, 1);
      expect(r.single.days.length, 1);
      expect(r.single.windowHours, closeTo(1.5, 1e-9));
      expect(r.single.served, 3);
      expect(r.single.perHour, closeTo(2.0, 1e-9));
    });

    test('no_show entra no intervalo mas nao no numerador', () {
      final r = computeOperatorRates([
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 12),
          finished: t(10, 12, 10),
        ),
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 12, 20),
          finished: t(10, 12, 30),
        ),
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 13),
          finished: t(10, 13, 30),
        ),
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 13, 30),
          finished: t(10, 13, 45),
          result: 'no_show',
        ),
      ]);
      expect(r.single.windowHours, closeTo(1.75, 1e-9));
      expect(r.single.perHour, closeTo(3 / 1.75, 1e-9));
    });

    test('dia com poucas amostras fica sem taxa e fora do agregado', () {
      final r = computeOperatorRates([
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 12),
          finished: t(10, 12, 30),
        ),
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 13),
          finished: t(10, 13, 30),
        ),
      ]);
      expect(r.single.days.single.perHour, isNull);
      expect(r.single.perHour, isNull);
      expect(r.single.served, 0);
      final low = computeOperatorRates([
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 12),
          finished: t(10, 13),
        ),
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 13),
          finished: t(10, 14),
        ),
      ], minSamples: 2);
      expect(low.single.perHour, closeTo(1.0, 1e-9));
    });

    test('dias separados pela virada em Sao Paulo', () {
      final r = computeOperatorRates([
        handled(
          by: 'a',
          joined: t(10, 1),
          called: t(11, 2, 30),
          finished: t(11, 2, 40),
        ),
        handled(
          by: 'a',
          joined: t(10, 1),
          called: t(11, 3, 10),
          finished: t(11, 3, 20),
        ),
      ], minSamples: 1);
      expect(r.single.days.length, 2);
      expect(r.single.days.first.day, DateTime.utc(2026, 5, 10));
      expect(r.single.days.last.day, DateTime.utc(2026, 5, 11));
    });

    test('vazio e entries sem datas', () {
      expect(computeOperatorRates([]), isEmpty);
      final e = HistoryEntry(
        id: 'z',
        ticket: 1,
        name: 'x',
        result: 'served',
        joinedAt: t(10, 10),
        calledBy: 'a',
      );
      final r = computeOperatorRates([e]);
      expect(r.single.days, isEmpty);
      expect(r.single.perHour, isNull);
    });
  });

  group('computeOperatorIdle', () {
    List<HistoryEntry> day() => [
      handled(
        by: 'a',
        joined: t(10, 11),
        called: t(10, 12),
        finished: t(10, 12, 10),
      ),
      handled(
        by: 'a',
        joined: t(10, 11, 30),
        called: t(10, 12, 20),
        finished: t(10, 12, 30),
      ),
      handled(
        by: 'a',
        joined: t(10, 12, 45),
        called: t(10, 13),
        finished: t(10, 13, 30),
      ),
      handled(
        by: 'a',
        joined: t(10, 12),
        called: t(10, 14, 30),
        finished: t(10, 14, 40),
      ),
    ];

    test('soma gaps com fila e ignora gap sem fila e acima do teto', () {
      final r = computeOperatorIdle(day()).single;
      expect(r.gaps, 1);
      expect(r.idleMin, closeTo(10, 1e-9));
      expect(r.observedMin, closeTo(160, 1e-9));
      expect(r.idlePct, closeTo(10 / 160, 1e-9));
    });

    test('teto configuravel', () {
      final r = computeOperatorIdle(day(), idleCapMin: 60).single;
      expect(r.gaps, 2);
      expect(r.idleMin, closeTo(70, 1e-9));
      expect(r.idlePct, closeTo(70 / 160, 1e-9));
    });

    test('gap que cruza a virada do dia nao conta', () {
      final r = computeOperatorIdle([
        handled(
          by: 'b',
          joined: t(10, 2),
          called: t(11, 2, 30),
          finished: t(11, 2, 50),
        ),
        handled(
          by: 'b',
          joined: t(11, 2),
          called: t(11, 3, 10),
          finished: t(11, 3, 20),
        ),
      ]).single;
      expect(r.gaps, 0);
      expect(r.idleMin, 0);
      expect(r.observedMin, closeTo(30, 1e-9));
      expect(r.idlePct, 0);
    });

    test('vazio e sem tempo observado', () {
      expect(computeOperatorIdle([]), isEmpty);
      final r = computeOperatorIdle([
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 12),
          finished: t(10, 12),
        ),
      ]).single;
      expect(r.idlePct, isNull);
      expect(r.gaps, 0);
    });
  });

  group('compareOperators', () {
    final entries = [
      for (final m in [4, 4, 4]) svc('a', m),
      for (final m in [8, 8, 8]) svc('b', m),
      for (final m in [10, 10]) svc('c', m),
    ];

    test('desvio contra a media do escopo e ranking', () {
      final stats = computeOperatorMetrics(entries);
      final rep = compareOperators(stats);
      expect(rep.scopeAvgMin, closeTo(6, 1e-9));
      final byId = {for (final r in rep.rows) r.stats.attendantId: r};
      expect(byId['a']!.deviationPct, closeTo(-100 / 3, 1e-9));
      expect(byId['a']!.rank, 1);
      expect(byId['b']!.deviationPct, closeTo(100 / 3, 1e-9));
      expect(byId['b']!.rank, 2);
      expect(byId['c']!.deviationPct, isNull);
      expect(byId['c']!.rank, isNull);
    });

    test('amostra minima maior que a disponivel', () {
      final rep = compareOperators(
        computeOperatorMetrics(entries),
        minSamples: 4,
      );
      expect(rep.scopeAvgMin, isNull);
      expect(
        rep.rows.every((r) => r.rank == null && r.deviationPct == null),
        isTrue,
      );
    });

    test('vazio', () {
      final rep = compareOperators([]);
      expect(rep.rows, isEmpty);
      expect(rep.scopeAvgMin, isNull);
    });
  });

  group('fuso e entradas atipicas', () {
    test('hora e dia independem do fuso do aparelho', () {
      final inst = t(11, 2, 59);
      expect(spHour(inst), 23);
      expect(spDay(inst), DateTime.utc(2026, 5, 10));
      expect(spHour(inst.toLocal()), 23);
      expect(spDay(inst.toLocal()), DateTime.utc(2026, 5, 10));
      final next = t(11, 3);
      expect(spHour(next.toLocal()), 0);
      expect(spDay(next.toLocal()), DateTime.utc(2026, 5, 11));
      HistoryEntry f(DateTime fin) => handled(
        by: 'a',
        joined: fin.subtract(const Duration(minutes: 20)),
        called: fin.subtract(const Duration(minutes: 5)),
        finished: fin,
      );
      final utc = computeOperatorThroughput([f(inst), f(next)]).single;
      final local = computeOperatorThroughput([
        f(inst.toLocal()),
        f(next.toLocal()),
      ]).single;
      expect(local.byHour, utc.byHour);
      expect(local.byDay, utc.byDay);
      expect(utc.byHour[23], 1);
      expect(utc.byHour[0], 1);
    });

    test('vazao ignora no_show e served sem datas', () {
      final noShow = HistoryEntry(
        id: 'n',
        ticket: 1,
        name: 'x',
        result: 'no_show',
        joinedAt: t(10, 10),
        finishedAt: t(10, 15),
        calledBy: 'a',
      );
      final bare = HistoryEntry(
        id: 'b',
        ticket: 1,
        name: 'x',
        result: 'served',
        joinedAt: t(10, 10),
        calledBy: 'a',
      );
      expect(computeOperatorThroughput([noShow, bare]), isEmpty);
    });

    test('finishedAt antes de calledAt e descartado em taxa e ociosidade', () {
      final bad = handled(
        by: 'a',
        joined: t(10, 11),
        called: t(10, 13),
        finished: t(10, 12),
      );
      expect(computeOperatorRates([bad]).single.days, isEmpty);
      final idle = computeOperatorIdle([bad]).single;
      expect(idle.gaps, 0);
      expect(idle.idlePct, isNull);
    });

    test('piso da janela de atuacao', () {
      List<HistoryEntry> three() => [
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 12),
          finished: t(10, 12, 5),
        ),
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 12, 10),
          finished: t(10, 12, 15),
        ),
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 12, 20),
          finished: t(10, 12, 25),
        ),
      ];
      expect(computeOperatorRates(three()).single.perHour, isNull);
      final r = computeOperatorRates(three(), minWindowMin: 20).single;
      expect(r.perHour, closeTo(3 / (25 / 60), 1e-9));
    });

    test('ociosidade com atendimentos sobrepostos usa o maior finishedAt', () {
      final r = computeOperatorIdle([
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 12),
          finished: t(10, 13),
        ),
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 12, 10),
          finished: t(10, 12, 20),
        ),
        handled(
          by: 'a',
          joined: t(10, 11),
          called: t(10, 13, 10),
          finished: t(10, 13, 20),
        ),
      ]).single;
      expect(r.gaps, 1);
      expect(r.idleMin, closeTo(10, 1e-9));
      expect(r.observedMin, closeTo(80, 1e-9));
      expect(r.idlePct, closeTo(0.125, 1e-9));
    });

    test('empate de ranking desempata por volume', () {
      final entries = [
        for (var i = 0; i < 3; i++) svc('a', 5),
        for (var i = 0; i < 3; i++) svc('b', 5),
        handled(
          by: 'b',
          joined: t(10, 12),
          called: t(10, 12),
          finished: t(10, 12, 5),
          result: 'no_show',
        ),
      ];
      final rep = compareOperators(computeOperatorMetrics(entries));
      final byId = {for (final r in rep.rows) r.stats.attendantId: r};
      expect(byId['b']!.rank, 1);
      expect(byId['a']!.rank, 2);
      expect(byId['a']!.deviationPct, closeTo(0, 1e-9));
    });
  });

  group('joinedAt na epoca 0', () {
    test('ociosidade ignora entrada sem joinedAt', () {
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      final a = handled(
        by: 'u',
        joined: t(10, 11),
        called: t(10, 12),
        finished: t(10, 12, 10),
      );
      final b = handled(
        by: 'u',
        joined: t(10, 11),
        called: t(10, 12, 20),
        finished: t(10, 12, 30),
      );
      final broken = handled(
        by: 'u',
        joined: epoch,
        called: t(10, 12, 40),
        finished: t(10, 12, 50),
      );
      final r = computeOperatorIdle([a, b, broken]).single;
      expect(r.gaps, 1);
      expect(r.idleMin, 10);
      expect(r.observedMin, 30);
    });
  });

  group('buildAttendantRows base consistente', () {
    test('tabela e grafico descartam as mesmas entradas', () {
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      final ok = [for (var i = 0; i < 3; i++) svc('u', 5 + i)];
      final noTimes = HistoryEntry(
        id: 'nt',
        ticket: 1,
        name: 'x',
        result: 'served',
        joinedAt: t(10, 11),
        calledBy: 'u',
      );
      final noJoin = handled(
        by: 'u',
        joined: epoch,
        called: t(10, 12),
        finished: t(10, 12, 5),
      );
      final rows = buildAttendantRows([...ok, noTimes, noJoin]);
      final row = rows.single;
      expect(row.stats.served, 3);
      expect(row.byHour.fold<int>(0, (a, b) => a + b), row.stats.served);
      expect(
        row.byShift.values.fold<int>(0, (a, b) => a + b),
        row.stats.served,
      );
      expect(sumByHour(rows).fold<int>(0, (a, b) => a + b), 3);
    });
  });
}
