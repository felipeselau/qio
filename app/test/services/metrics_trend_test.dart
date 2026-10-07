import 'package:flutter_test/flutter_test.dart';
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
}
