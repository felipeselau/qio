import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/services/history_metrics.dart';

HistoryEntry entry({
  String id = 'a',
  String result = 'served',
  required DateTime joinedAt,
  DateTime? calledAt,
  DateTime? finishedAt,
}) => HistoryEntry(
  id: id,
  ticket: 1,
  name: 'Ana',
  result: result,
  joinedAt: joinedAt,
  calledAt: calledAt,
  finishedAt: finishedAt,
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
      expect(HistoryPeriod.today.label, 'Hoje');
      expect(HistoryPeriod.last7Days.label, '7 dias');
      expect(HistoryPeriod.all.label, 'Tudo');
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

    test('documento vazio', () {
      final e = HistoryEntry.fromDoc('x', {});
      expect(e.id, 'x');
      expect(e.joinedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });
}
