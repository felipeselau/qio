import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/services/staffing_metrics.dart';

int _n = 0;

HistoryEntry arrival(DateTime joined) => HistoryEntry(
  id: 'a${_n++}',
  ticket: 1,
  name: 'x',
  result: 'left',
  joinedAt: joined,
  finishedAt: joined.add(const Duration(minutes: 1)),
);

HistoryEntry served(
  String by,
  DateTime joined,
  DateTime called, {
  int serviceMin = 20,
  String result = 'served',
  DateTime? finished,
}) => HistoryEntry(
  id: 's${_n++}',
  ticket: 1,
  name: 'x',
  result: result,
  joinedAt: joined,
  calledAt: called,
  finishedAt: finished ?? called.add(Duration(minutes: serviceMin)),
  calledBy: by,
);

DateTime u(int month, int day, int hour, [int minute = 0]) =>
    DateTime.utc(2026, month, day, hour, minute);

List<HistoryEntry> grid() => [
  served('op1', u(5, 4, 15), u(5, 4, 15)),
  served('op1', u(5, 4, 15, 5), u(5, 4, 15, 20)),
  served('op2', u(5, 4, 15, 10), u(5, 4, 15, 10)),
  served('op2', u(5, 4, 15, 15), u(5, 4, 15, 30)),
  served('op1', u(5, 11, 15), u(5, 11, 15)),
  served('op1', u(5, 11, 15, 5), u(5, 11, 15, 20)),
  served('op1', u(5, 5, 17), u(5, 5, 17)),
  for (var i = 0; i < 6; i++) arrival(u(5, 9, 13, i)),
];

void main() {
  group('grade de dimensionamento', () {
    test('vazio', () {
      final g = computeStaffingGrid(const []);
      expect(g.hasArrivals, isFalse);
      expect(g.hasRequirement, isFalse);
      expect(g.topDeficits, isEmpty);
      expect(g.cells.length, 7);
      expect(g.cells.first.length, 24);
    });

    test('chegadas por hora dividem pelas ocorrências do dia da semana', () {
      final g = computeStaffingGrid(grid());
      expect(g.coverageDays, 8);
      final mon = g.cells[0][12];
      expect(mon.arrivals, closeTo(3.0, 1e-9));
      expect(g.cells[1][14].arrivals, closeTo(1.0, 1e-9));
      expect(g.cells[5][10].arrivals, closeTo(6.0, 1e-9));
      expect(g.cells[0][11].arrivals, 0);
    });

    test('tempo médio de atendimento e necessário', () {
      final g = computeStaffingGrid(grid());
      expect(g.serviceSamples, 7);
      expect(g.avgServiceMin, closeTo(20, 1e-9));
      expect(g.hasRequirement, isTrue);
      expect(g.cells[0][12].required, 2);
      expect(g.cells[1][14].required, 1);
      expect(g.cells[5][10].required, 3);
      expect(g.cells[3][3].required, 0);
    });

    test('observados: média de operadores distintos por ocorrência', () {
      final g = computeStaffingGrid(grid());
      expect(g.cells[0][12].observed, closeTo(1.5, 1e-9));
      expect(g.cells[1][14].observed, closeTo(1.0, 1e-9));
      expect(g.cells[5][10].observed, 0);
      expect(g.cells[0][12].gap, closeTo(0.5, 1e-9));
    });

    test('piores déficits ordenados e sem folga', () {
      final g = computeStaffingGrid(grid());
      expect(g.topDeficits.length, 2);
      expect(g.topDeficits[0].weekday, 5);
      expect(g.topDeficits[0].hour, 10);
      expect(g.topDeficits[0].gap, closeTo(3, 1e-9));
      expect(g.topDeficits[1].weekday, 0);
      expect(g.topDeficits[1].hour, 12);
      expect(
        computeStaffingGrid(grid(), deficitLimit: 1).topDeficits.length,
        1,
      );
    });

    test('ocupação alvo muda o necessário', () {
      expect(computeStaffingGrid(grid()).cells[0][12].required, 2);
      expect(
        computeStaffingGrid(grid(), occupancy: 1.0).cells[0][12].required,
        1,
      );
    });

    test('sem amostras de atendimento não calcula necessário', () {
      final g = computeStaffingGrid([
        served('op1', u(5, 4, 15), u(5, 4, 15)),
        served('op1', u(5, 4, 15), u(5, 4, 15, 30)),
        arrival(u(5, 4, 16)),
      ]);
      expect(g.avgServiceMin, isNull);
      expect(g.hasRequirement, isFalse);
      expect(g.cells[0][13].required, 0);
      expect(g.cells[0][13].arrivals, 1);
      expect(g.topDeficits, isEmpty);
    });

    test('atendimento que cruza a hora conta nas duas', () {
      final g = computeStaffingGrid([
        served('op1', u(5, 4, 15, 40), u(5, 4, 15, 50), serviceMin: 20),
      ]);
      expect(g.cells[0][12].observed, 1);
      expect(g.cells[0][13].observed, 1);
      expect(g.cells[0][14].observed, 0);
    });

    test('término exatamente na virada da hora não conta a hora seguinte', () {
      final g = computeStaffingGrid([
        served('op1', u(5, 4, 15, 40), u(5, 4, 15, 50), serviceMin: 10),
      ]);
      expect(g.cells[0][12].observed, 1);
      expect(g.cells[0][13].observed, 0);
    });

    test('dono e atendente sem id são o mesmo operador', () {
      final g = computeStaffingGrid(
        [
          served('own', u(5, 4, 15), u(5, 4, 15)),
          HistoryEntry(
            id: 'x',
            ticket: 1,
            name: 'x',
            result: 'served',
            joinedAt: u(5, 4, 15),
            calledAt: u(5, 4, 15, 20),
            finishedAt: u(5, 4, 15, 40),
          ),
        ],
        ownerUids: {'own'},
      );
      expect(g.cells[0][12].observed, 1);
    });

    test('hora em São Paulo, não UTC', () {
      final g = computeStaffingGrid([arrival(u(5, 5, 2, 30))]);
      expect(g.cells[0][23].arrivals, 1);
      expect(g.cells[1][23].arrivals, 0);
    });

    test('joinedAt na época 0 é descartado', () {
      final g = computeStaffingGrid([
        HistoryEntry(
          id: 'z',
          ticket: 1,
          name: 'x',
          result: 'left',
          joinedAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ]);
      expect(g.hasArrivals, isFalse);
    });
  });

  group('sazonalidade', () {
    final now = u(6, 15, 15);

    List<HistoryEntry> monday12(List<int> perWeek) => [
      for (var w = 0; w < perWeek.length; w++)
        for (var i = 0; i < perWeek[w]; i++) arrival(u(5, 4 + 7 * w, 15)),
    ];

    test('sem dados', () {
      final s = computeSeasonality(const [], now: now);
      expect(s.weeks, isEmpty);
      expect(s.insufficient, isTrue);
    });

    test('tendência é a inclinação em % da média por semana', () {
      final s = computeSeasonality(
        monday12([10, 12, 14, 16, 18, 20]),
        now: now,
      );
      expect(s.observedWeeks, 6);
      expect(s.insufficient, isFalse);
      expect(s.weeks.first.weekStart, DateTime.utc(2026, 5, 4));
      expect(s.weeks.map((w) => w.volume).toList(), [10, 12, 14, 16, 18, 20]);
      expect(s.trendPct, closeTo(2 / 15 * 100, 1e-9));
      expect(s.direction, TrendDirection.up);
    });

    test('tendência de queda e estável', () {
      final down = computeSeasonality(
        monday12([20, 16, 12, 8]),
        now: u(6, 1, 15),
      );
      expect(down.trendPct, closeTo(-4 / 14 * 100, 1e-9));
      expect(down.direction, TrendDirection.down);
      final flat = computeSeasonality(
        monday12([10, 10, 10, 10]),
        now: u(6, 1, 15),
      );
      expect(flat.trendPct, closeTo(0, 1e-9));
      expect(flat.direction, TrendDirection.stable);
    });

    test('menos de 3 semanas é dados insuficientes', () {
      final s = computeSeasonality(monday12([10, 12]), now: u(5, 18, 15));
      expect(s.insufficient, isTrue);
      expect(s.observedWeeks, 2);
      expect(s.trendPct, isNull);
      expect(s.recurring, isEmpty);
    });

    test('semana atual e anteriores à janela ficam de fora', () {
      final s = computeSeasonality([
        ...monday12([3, 3, 3]),
        arrival(u(6, 15, 15)),
        arrival(u(6, 17, 15)),
        arrival(u(4, 19, 15)),
      ], now: now);
      expect(s.weeks.map((w) => w.volume).toList(), [3, 3, 3, 0, 0, 0]);
      expect(s.observedWeeks, 6);
    });

    test('semanas sem dados depois da primeira contam como zero', () {
      final s = computeSeasonality(monday12([10, 12, 14]), now: now);
      expect(s.weeks.map((w) => w.volume).toList(), [10, 12, 14, 0, 0, 0]);
    });

    test('semanas vazias no meio contam como zero e as iniciais não', () {
      final s = computeSeasonality([
        arrival(u(5, 18, 15)),
        arrival(u(6, 8, 15)),
        arrival(u(6, 8, 16)),
      ], now: now);
      expect(s.weeks.first.weekStart, DateTime.utc(2026, 5, 18));
      expect(s.weeks.map((w) => w.volume).toList(), [1, 0, 0, 2]);
    });

    test('semana vai de segunda a domingo em São Paulo', () {
      final s = computeSeasonality([
        arrival(u(5, 11, 2, 59)),
        arrival(u(5, 11, 3)),
        arrival(u(5, 4, 15)),
        arrival(u(5, 18, 15)),
      ], now: now);
      expect(s.weeks.map((w) => w.volume).toList(), [2, 1, 1, 0, 0, 0]);
      expect(s.weeks.first.weekStart, DateTime.utc(2026, 5, 4));
    });

    List<HistoryEntry> pattern() {
      final out = <HistoryEntry>[];
      for (var w = 0; w < 6; w++) {
        final monday = 4 + 7 * w;
        final wedCount = w < 4 ? 3 : 1;
        final friCount = w < 4 ? 1 : 3;
        for (var i = 0; i < 5; i++) {
          out.add(arrival(u(5, monday, 15)));
        }
        for (var i = 0; i < wedCount; i++) {
          out.add(arrival(u(5, monday + 2, 13)));
        }
        for (var i = 0; i < friCount; i++) {
          out.add(arrival(u(5, monday + 4, 12)));
        }
      }
      return out;
    }

    test('padrão recorrente exige 70% das semanas no top-X', () {
      final s = computeSeasonality(pattern(), now: now, topCells: 2);
      expect(s.recurring.length, 1);
      expect(s.recurring.single.weekday, 0);
      expect(s.recurring.single.hour, 12);
      expect(s.recurring.single.weeks, 6);
      expect(s.recurring.single.observedWeeks, 6);
      expect(s.trendPct, closeTo(0, 1e-9));
    });

    test('limiar de recorrência é parâmetro', () {
      final s = computeSeasonality(
        pattern(),
        now: now,
        topCells: 2,
        recurrenceMinPct: 60,
      );
      expect(s.recurring.map((c) => (c.weekday, c.hour, c.weeks)).toList(), [
        (0, 12, 6),
        (2, 10, 4),
      ]);
    });

    test('top-X padrão inclui as células mais cheias de cada semana', () {
      final s = computeSeasonality(pattern(), now: now);
      expect(s.recurring.length, 3);
    });
  });

  test('buildStaffingReport junta grade e sazonalidade', () {
    final r = buildStaffingReport(
      grid(),
      seasonEntries: grid(),
      now: u(5, 18, 15),
    );
    expect(r.hasData, isTrue);
    expect(r.grid.cells[0][12].required, 2);
    expect(r.seasonality.weeks.first.weekStart, DateTime.utc(2026, 5, 4));
    expect(r.seasonality.insufficient, isTrue);
  });
}
