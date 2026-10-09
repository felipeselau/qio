import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/services/metrics_trend.dart';

HistoryEntry entry({
  String id = 'a',
  String result = 'served',
  required DateTime joinedAt,
  DateTime? calledAt,
  DateTime? finishedAt,
  int recalls = 0,
  int skips = 0,
}) => HistoryEntry(
  id: id,
  ticket: 1,
  name: 'Ana',
  result: result,
  joinedAt: joinedAt,
  calledAt: calledAt,
  finishedAt: finishedAt,
  recalls: recalls,
  skips: skips,
);

void main() {
  final base = DateTime(2026, 5, 10, 12);

  group('computeHistoryMetrics', () {
    test('lista vazia', () {
      final m = computeHistoryMetrics([]);
      expect(m.total, 0);
      expect(m.served, 0);
      expect(m.noShow, 0);
      expect(m.noShowRate, 0);
      expect(m.avgWaitMin, isNull);
      expect(m.avgServiceMin, isNull);
    });

    test('somente no_show', () {
      final m = computeHistoryMetrics([
        entry(
          result: 'no_show',
          joinedAt: base,
          calledAt: base.add(const Duration(minutes: 4)),
          finishedAt: base.add(const Duration(minutes: 6)),
        ),
        entry(
          id: 'b',
          result: 'no_show',
          joinedAt: base,
          calledAt: base.add(const Duration(minutes: 6)),
          finishedAt: base.add(const Duration(minutes: 8)),
        ),
      ]);
      expect(m.noShowRate, 1);
      expect(m.served, 0);
      expect(m.avgWaitMin, 5);
      expect(m.avgServiceMin, isNull);
    });

    test('left conta como desistência e fora da taxa de no_show', () {
      final m = computeHistoryMetrics([
        entry(joinedAt: base),
        entry(id: 'b', result: 'no_show', joinedAt: base),
        entry(id: 'c', result: 'left', joinedAt: base),
        entry(id: 'd', result: 'left', joinedAt: base),
      ]);
      expect(m.total, 4);
      expect(m.left, 2);
      expect(m.noShow, 1);
      expect(m.noShowRate, 0.25);
      expect(m.avgServiceMin, isNull);
    });

    test('calledAt nulo fica fora das médias', () {
      final m = computeHistoryMetrics([
        entry(joinedAt: base, finishedAt: base.add(const Duration(minutes: 9))),
      ]);
      expect(m.total, 1);
      expect(m.avgWaitMin, isNull);
      expect(m.avgServiceMin, isNull);
    });

    test('mix com médias corretas', () {
      final m = computeHistoryMetrics([
        entry(
          joinedAt: base,
          calledAt: base.add(const Duration(minutes: 10)),
          finishedAt: base.add(const Duration(minutes: 15)),
        ),
        entry(
          id: 'b',
          joinedAt: base,
          calledAt: base.add(const Duration(minutes: 20)),
          finishedAt: base.add(const Duration(minutes: 35)),
        ),
        entry(
          id: 'c',
          result: 'no_show',
          joinedAt: base,
          calledAt: base.add(const Duration(minutes: 30)),
          finishedAt: base.add(const Duration(minutes: 31)),
        ),
        entry(id: 'd', result: 'no_show', joinedAt: base),
      ]);
      expect(m.total, 4);
      expect(m.served, 2);
      expect(m.noShow, 2);
      expect(m.noShowRate, 0.5);
      expect(m.avgWaitMin, 20);
      expect(m.avgServiceMin, 10);
    });
  });

  group('filterHistory', () {
    final now = DateTime(2026, 5, 10, 15);
    final todayEntry = entry(
      id: 'today',
      joinedAt: DateTime(2026, 5, 10, 9),
      finishedAt: DateTime(2026, 5, 10, 10),
    );
    final threeDays = entry(
      id: 'three',
      result: 'no_show',
      joinedAt: DateTime(2026, 5, 7, 9),
      finishedAt: DateTime(2026, 5, 7, 10),
    );
    final old = entry(
      id: 'old',
      joinedAt: DateTime(2026, 4, 1, 9),
      finishedAt: DateTime(2026, 4, 1, 10),
    );
    final pending = entry(id: 'pending', joinedAt: DateTime(2026, 5, 10, 14));
    final all = [todayEntry, threeDays, old, pending];

    List<String> ids(List<HistoryEntry> l) => l.map((e) => e.id).toList();

    test('por resultado', () {
      expect(ids(filterHistory(all, result: 'no_show', now: now)), ['three']);
      expect(ids(filterHistory(all, result: 'served', now: now)), [
        'today',
        'old',
        'pending',
      ]);
    });

    test('filtra desistências', () {
      final left = entry(
        id: 'left',
        result: 'left',
        joinedAt: DateTime(2026, 5, 10, 9),
        finishedAt: DateTime(2026, 5, 10, 9, 30),
      );
      expect(ids(filterHistory([...all, left], result: 'left', now: now)), [
        'left',
      ]);
    });

    test('hoje', () {
      expect(ids(filterHistory(all, period: HistoryPeriod.today, now: now)), [
        'today',
        'pending',
      ]);
    });

    test('7 dias', () {
      expect(
        ids(filterHistory(all, period: HistoryPeriod.last7Days, now: now)),
        ['today', 'three', 'pending'],
      );
    });

    test('7 dias usa dias de calendário', () {
      final edgeIn = entry(id: 'in', joinedAt: DateTime(2026, 5, 4));
      final edgeOut = entry(id: 'out', joinedAt: DateTime(2026, 5, 3, 23, 59));
      expect(
        ids(
          filterHistory(
            [edgeIn, edgeOut],
            period: HistoryPeriod.last7Days,
            now: now,
          ),
        ),
        ['in'],
      );
    });

    test('personalizado filtra pela faixa', () {
      expect(
        ids(
          filterHistory(
            all,
            period: HistoryPeriod.custom,
            now: now,
            custom: DateRange(DateTime(2026, 5, 7), DateTime(2026, 5, 8)),
          ),
        ),
        ['three'],
      );
    });

    test('personalizado sem faixa não vira tudo', () {
      expect(
        filterHistory(all, period: HistoryPeriod.custom, now: now),
        isEmpty,
      );
    });

    test('tudo e combinação', () {
      expect(filterHistory(all, now: now).length, 4);
      expect(
        ids(
          filterHistory(
            all,
            result: 'served',
            period: HistoryPeriod.today,
            now: now,
          ),
        ),
        ['today', 'pending'],
      );
    });

    test('labels', () {
      final pt = lookupAppLocalizations(const Locale('pt'));
      expect(HistoryPeriod.today.label(pt), 'Hoje');
      expect(HistoryPeriod.last7Days.label(pt), '7 dias');
      expect(HistoryPeriod.all.label(pt), 'Tudo');
      expect(HistoryPeriod.last30Days.label(pt), '30 dias');
      expect(HistoryPeriod.custom.label(pt), 'Personalizado');
      expect(HistoryPeriod.last30Days.fileSlug, '30dias');
      expect(HistoryPeriod.custom.fileSlug, 'personalizado');
      final en = lookupAppLocalizations(const Locale('en'));
      expect(HistoryPeriod.last7Days.label(en), '7 days');
    });
  });

  group('HistoryEntry.fromDoc', () {
    test('campos completos', () {
      final e = HistoryEntry.fromDoc('x', {
        'ticket': 7,
        'name': 'Bia',
        'phone': '11999',
        'result': 'served',
        'joinedAt': Timestamp.fromDate(DateTime(2026, 5, 10, 9)),
        'calledAt': Timestamp.fromDate(DateTime(2026, 5, 10, 9, 5)),
        'finishedAt': Timestamp.fromDate(DateTime(2026, 5, 10, 9, 15)),
      });
      expect(e.ticket, 7);
      expect(e.wait, const Duration(minutes: 5));
      expect(e.service, const Duration(minutes: 10));
    });

    test('campos faltando e finishedAt pendente', () {
      final e = HistoryEntry.fromDoc('x', {
        'joinedAt': Timestamp.fromDate(DateTime(2026, 5, 10, 9)),
        'calledAt': null,
        'finishedAt': null,
      });
      expect(e.ticket, 0);
      expect(e.name, '');
      expect(e.phone, isNull);
      expect(e.result, '');
      expect(e.calledAt, isNull);
      expect(e.finishedAt, isNull);
      expect(e.wait, isNull);
      expect(e.service, isNull);
      expect(e.referenceTime, DateTime(2026, 5, 10, 9));
    });

    test('result left', () {
      final e = HistoryEntry.fromDoc('x', {'result': 'left'});
      expect(e.isLeft, isTrue);
      expect(e.isServed, isFalse);
      expect(e.isNoShow, isFalse);
    });

    test('reason expired/closed não conta como desistência', () {
      final e = HistoryEntry.fromDoc('x', {
        'result': 'left',
        'reason': 'expired',
      });
      expect(e.isLeft, isTrue);
      expect(e.isSystemRemoved, isTrue);
      final m = computeHistoryMetrics([
        e,
        HistoryEntry.fromDoc('y', {'result': 'left'}),
        HistoryEntry.fromDoc('z', {'result': 'left', 'reason': 'closed'}),
      ]);
      expect(m.left, 1);
      expect(m.total, 3);
    });

    test('documento vazio', () {
      final e = HistoryEntry.fromDoc('x', {});
      expect(e.id, 'x');
      expect(e.joinedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  HistoryEntry waited(
    double min, {
    String result = 'served',
    int recalls = 0,
    int skips = 0,
  }) => entry(
    result: result,
    joinedAt: base,
    calledAt: base.add(Duration(milliseconds: (min * 60000).round())),
    recalls: recalls,
    skips: skips,
  );

  group('computeWaitStats', () {
    test('vazio', () {
      final w = computeWaitStats([]);
      expect(w.samples, 0);
      expect(w.medianMin, isNull);
      expect(w.p90Min, isNull);
      expect(w.avgMin, isNull);
      expect(w.bucketCounts, [0, 0, 0, 0]);
    });

    test('n=1', () {
      final w = computeWaitStats([waited(7)]);
      expect(w.samples, 1);
      expect(w.medianMin, 7);
      expect(w.avgMin, 7);
      expect(w.p90Min, isNull);
      expect(w.bucketCounts, [0, 1, 0, 0]);
    });

    test('mediana impar e par', () {
      expect(computeWaitStats([waited(9), waited(1), waited(5)]).medianMin, 5);
      expect(
        computeWaitStats([
          waited(1),
          waited(2),
          waited(4),
          waited(10),
        ]).medianMin,
        3,
      );
    });

    test('P90 com 10 amostras e null com n<5', () {
      final w = computeWaitStats([
        for (var i = 1; i <= 10; i++) waited(i * 1.0),
      ]);
      expect(w.p90Min, 9);
      expect(w.avgMin, 5.5);
      final four = [for (var i = 1; i <= 4; i++) waited(i * 1.0)];
      expect(computeWaitStats(four).p90Min, isNull);
      final five = [for (var i = 1; i <= 5; i++) waited(i * 1.0)];
      expect(computeWaitStats(five).p90Min, 5);
    });

    test('limites 5/15/30 e soma das faixas', () {
      final w = computeWaitStats([
        waited(4.99),
        waited(5),
        waited(14.99),
        waited(15),
        waited(29.99),
        waited(30),
        waited(0),
      ]);
      expect(w.bucketCounts, [2, 2, 2, 1]);
      expect(w.bucketCounts.reduce((a, b) => a + b), w.samples);
    });

    test('left, sem calledAt e negativa ignorados; no_show entra', () {
      final w = computeWaitStats([
        waited(3, result: 'left'),
        waited(-2),
        entry(joinedAt: base),
        waited(6, result: 'no_show'),
      ]);
      expect(w.samples, 1);
      expect(w.medianMin, 6);
    });
  });

  group('computeCallEffort', () {
    test('vazio', () {
      final c = computeCallEffort([]);
      expect(c.called, 0);
      expect(c.recallRate, isNull);
      expect(c.recallsTotal, 0);
      expect(c.skipsTotal, 0);
    });

    test('somas, entries afetadas e taxa', () {
      final c = computeCallEffort([
        waited(1, recalls: 2),
        waited(1, recalls: 1, skips: 3, result: 'no_show'),
        waited(1),
        waited(1),
      ]);
      expect(c.called, 4);
      expect(c.recallsTotal, 3);
      expect(c.recalledEntries, 2);
      expect(c.skipsTotal, 3);
      expect(c.skippedEntries, 1);
      expect(c.recallRate, 0.5);
    });

    test('left fica fora, mesmo com calledAt, recalls e skips', () {
      final c = computeCallEffort([
        waited(1, recalls: 1),
        waited(2, result: 'left', recalls: 5, skips: 4),
        entry(result: 'left', joinedAt: base, skips: 1),
      ]);
      expect(c.called, 1);
      expect(c.recallsTotal, 1);
      expect(c.recalledEntries, 1);
      expect(c.skipsTotal, 0);
      expect(c.skippedEntries, 0);
      expect(c.recallRate, 1);
    });
  });
}
