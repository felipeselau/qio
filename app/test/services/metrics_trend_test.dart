import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/services/metrics_trend.dart';

void main() {
  group('rangeFor', () {
    final now = DateTime(2026, 10, 7, 15, 30);

    test('hoje tem 1 dia', () {
      final r = rangeFor(HistoryPeriod.today, now)!;
      expect(r.start, DateTime(2026, 10, 7));
      expect(r.end, DateTime(2026, 10, 8));
      expect(r.days, 1);
    });

    test('7 dias inclui hoje e 6 anteriores', () {
      final r = rangeFor(HistoryPeriod.last7Days, now)!;
      expect(r.start, DateTime(2026, 10, 1));
      expect(r.end, DateTime(2026, 10, 8));
      expect(r.days, 7);
    });

    test('30 dias inclui hoje e 29 anteriores', () {
      final r = rangeFor(HistoryPeriod.last30Days, now)!;
      expect(r.start, DateTime(2026, 9, 8));
      expect(r.end, DateTime(2026, 10, 8));
      expect(r.days, 30);
    });

    test('personalizado de 1 dia', () {
      final r = rangeFor(
        HistoryPeriod.custom,
        now,
        custom: DateRange(DateTime(2026, 5, 10, 14), DateTime(2026, 5, 10, 18)),
      )!;
      expect(r.start, DateTime(2026, 5, 10));
      expect(r.end, DateTime(2026, 5, 11));
      expect(r.days, 1);
    });

    test('personalizado invertido é normalizado', () {
      final r = rangeFor(
        HistoryPeriod.custom,
        now,
        custom: DateRange(DateTime(2026, 5, 20), DateTime(2026, 5, 10)),
      )!;
      expect(r.start, DateTime(2026, 5, 10));
      expect(r.end, DateTime(2026, 5, 20));
    });

    test('personalizado ignora horário e sem faixa é nulo', () {
      final r = rangeFor(
        HistoryPeriod.custom,
        now,
        custom: DateRange(DateTime(2026, 5, 1, 13), DateTime(2026, 5, 4, 9)),
      )!;
      expect(r, DateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 4)));
      expect(rangeFor(HistoryPeriod.custom, now), isNull);
    });

    test('tudo é nulo', () {
      expect(rangeFor(HistoryPeriod.all, now), isNull);
    });

    test('limites 00:00 e 23:59', () {
      final r = rangeFor(HistoryPeriod.today, now)!;
      expect(r.contains(DateTime(2026, 10, 7)), isTrue);
      expect(r.contains(DateTime(2026, 10, 7, 23, 59, 59)), isTrue);
      expect(r.contains(DateTime(2026, 10, 8)), isFalse);
      expect(r.contains(DateTime(2026, 10, 6, 23, 59, 59)), isFalse);
    });

    test('virada de mês no 7 dias', () {
      final r = rangeFor(HistoryPeriod.last7Days, DateTime(2026, 3, 3))!;
      expect(r.start, DateTime(2026, 2, 25));
      expect(r.days, 7);
    });
  });

  group('DateRange.previous', () {
    test('hoje em 1º de março não bissexto', () {
      final r = rangeFor(HistoryPeriod.today, DateTime(2026, 3, 1))!;
      expect(r.previous(), DateRange(DateTime(2026, 2, 28), DateTime(2026, 3)));
    });

    test('hoje em 1º de março bissexto', () {
      final r = rangeFor(HistoryPeriod.today, DateTime(2028, 3, 1))!;
      expect(r.previous(), DateRange(DateTime(2028, 2, 29), DateTime(2028, 3)));
    });

    test('7 dias na virada de ano', () {
      final r = rangeFor(HistoryPeriod.last7Days, DateTime(2026, 1, 3))!;
      expect(r.start, DateTime(2025, 12, 28));
      final p = r.previous();
      expect(p.start, DateTime(2025, 12, 21));
      expect(p.end, DateTime(2025, 12, 28));
      expect(p.days, 7);
    });

    test('mesma duração e adjacente', () {
      final r = DateRange(DateTime(2026, 3, 1), DateTime(2026, 3, 31));
      final p = r.previous();
      expect(p.days, r.days);
      expect(p.end, r.start);
      expect(p.start, DateTime(2026, 1, 30));
    });

    test('duração em dias não depende de horário de verão', () {
      final r = DateRange(DateTime(2026, 3, 7), DateTime(2026, 3, 9));
      expect(r.days, 2);
    });
  });

  HistoryEntry entry(
    String id,
    DateTime finished, {
    String result = 'served',
    int waitMin = 5,
  }) => HistoryEntry(
    id: id,
    ticket: 1,
    name: id,
    result: result,
    joinedAt: finished.subtract(Duration(minutes: waitMin + 10)),
    calledAt: finished.subtract(const Duration(minutes: 10)),
    finishedAt: finished,
  );

  group('dailySeries', () {
    final range = DateRange(DateTime(2026, 2, 27), DateTime(2026, 3, 3));

    test('preenche todos os dias com zero', () {
      final s = dailySeries([entry('a', DateTime(2026, 3, 1, 10))], range);
      expect(s.map((p) => p.day), [
        DateTime(2026, 2, 27),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 2),
      ]);
      expect(s.map((p) => p.total), [0, 0, 1, 0]);
      expect(s[0].avgWaitMin, isNull);
      expect(s[0].noShowRate, 0);
      expect(s[2].avgWaitMin, 5);
    });

    test('série vazia ainda tem um ponto por dia', () {
      expect(dailySeries(const [], range).length, 4);
    });

    test('limites 00:00 e 23:59 ficam no dia certo', () {
      final s = dailySeries([
        entry('a', DateTime(2026, 2, 28)),
        entry('b', DateTime(2026, 2, 27, 23, 59)),
        entry('c', DateTime(2026, 3, 2, 23, 59)),
        entry('d', DateTime(2026, 3, 3)),
        entry('e', DateTime(2026, 2, 26, 23, 59)),
      ], range);
      expect(s.map((p) => p.total), [1, 1, 0, 1]);
    });

    test('conta served, no_show e taxa por dia', () {
      final d = DateTime(2026, 3, 1, 9);
      final s = dailySeries([
        entry('a', d),
        entry('b', d, result: 'no_show'),
        entry('c', d, result: 'no_show'),
        entry('d', d, result: 'left'),
      ], range);
      expect(s[2].total, 4);
      expect(s[2].served, 1);
      expect(s[2].noShow, 2);
      expect(s[2].noShowRate, 0.5);
    });

    test('atravessa mudança de horário de verão sem pular dia', () {
      final r = DateRange(DateTime(2026, 11, 1), DateTime(2026, 11, 9));
      final s = dailySeries(const [], r);
      expect(s.length, 8);
      expect(s.last.day, DateTime(2026, 11, 8));
    });
  });

  group('compare', () {
    HistoryMetrics m(List<HistoryEntry> e) => computeHistoryMetrics(e);
    final d = DateTime(2026, 3, 1, 9);

    test('anterior vazio não gera deltas', () {
      expect(compare(m([entry('a', d)]), m(const [])), isEmpty);
    });

    test('aumento e queda em total', () {
      final prev = m([entry('a', d), entry('b', d)]);
      final up = compare(
        m([entry('a', d), entry('b', d), entry('c', d)]),
        prev,
      );
      expect(up[MetricKey.total]!.pct, 50);
      expect(up[MetricKey.total]!.abs, 1);
      final down = compare(m([entry('a', d)]), prev);
      expect(down[MetricKey.total]!.pct, -50);
    });

    test('no-show em pontos percentuais', () {
      final prev = m([entry('a', d), entry('b', d, result: 'no_show')]);
      final cur = m([
        entry('a', d),
        entry('b', d, result: 'no_show'),
        entry('c', d, result: 'no_show'),
        entry('e', d, result: 'no_show'),
      ]);
      final delta = compare(cur, prev)[MetricKey.noShowRate]!;
      expect(delta.abs, 25);
      expect(delta.pct, 50);
    });

    test('no-show anterior zero mantém pontos e omite pct', () {
      final prev = m([entry('a', d)]);
      final cur = m([entry('a', d), entry('b', d, result: 'no_show')]);
      final delta = compare(cur, prev)[MetricKey.noShowRate]!;
      expect(delta.abs, 50);
      expect(delta.pct, isNull);
    });

    test('valor anterior zero ou nulo é omitido', () {
      final noWait = HistoryEntry(
        id: 'x',
        ticket: 1,
        name: 'x',
        result: 'served',
        joinedAt: d,
        finishedAt: d,
      );
      final deltas = compare(m([entry('a', d)]), m([noWait]));
      expect(deltas.containsKey(MetricKey.avgWait), isFalse);
      expect(deltas.containsKey(MetricKey.avgService), isFalse);
      expect(deltas.containsKey(MetricKey.total), isTrue);
    });

    test('espera média e mediana', () {
      final prev = [entry('a', d, waitMin: 10)];
      final cur = [entry('a', d, waitMin: 5)];
      final deltas = compare(
        m(cur),
        m(prev),
        curWait: computeWaitStats(cur),
        prevWait: computeWaitStats(prev),
      );
      expect(deltas[MetricKey.avgWait]!.pct, -50);
      expect(deltas[MetricKey.waitMedian]!.pct, -50);
      expect(deltas.containsKey(MetricKey.waitP90), isFalse);
    });
  });
}
