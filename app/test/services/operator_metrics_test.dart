import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/models/queue_feedback.dart';
import 'package:qio_app/services/operator_metrics.dart';

final base = DateTime(2026, 5, 10, 12);

HistoryEntry entry(
  String id, {
  String result = 'served',
  String? calledBy,
  String? operatorId,
  int serviceMin = 5,
}) => HistoryEntry(
  id: id,
  ticket: 1,
  name: 'Ana',
  result: result,
  joinedAt: base,
  calledAt: base,
  finishedAt: base.add(Duration(minutes: serviceMin)),
  calledBy: calledBy,
  operatorId: operatorId,
);

void main() {
  group('computeOperatorMetrics', () {
    test('lista vazia', () {
      expect(computeOperatorMetrics([], ownerUids: {'o'}), isEmpty);
    });

    test('agrupa por atendente e ordena por volume', () {
      final stats = computeOperatorMetrics(
        [
          entry('1', calledBy: 'a'),
          entry('2', calledBy: 'b'),
          entry('3', calledBy: 'b'),
          entry('4', calledBy: 'b', result: 'no_show'),
        ],
        ownerUids: {'o'},
      );
      expect(stats.map((s) => s.attendantId), ['b', 'a']);
      expect(stats.first.served, 2);
      expect(stats.first.noShow, 1);
    });

    test('calledBy tem prioridade sobre operatorId', () {
      final stats = computeOperatorMetrics(
        [entry('1', calledBy: 'a', operatorId: 'o')],
        ownerUids: {'o'},
      );
      expect(stats.single.attendantId, 'a');
    });

    test('sem atendente e uid do dono caem no mesmo balde', () {
      final stats = computeOperatorMetrics(
        [entry('1'), entry('2', operatorId: 'o'), entry('3', calledBy: 'o')],
        ownerUids: {'o'},
      );
      expect(stats, hasLength(1));
      expect(stats.single.isOwner, isTrue);
      expect(stats.single.served, 3);
    });

    test('ignora left', () {
      final stats = computeOperatorMetrics(
        [entry('1', calledBy: 'a', result: 'left')],
        ownerUids: {'o'},
      );
      expect(stats, isEmpty);
    });

    test('tempo medio exige 3 amostras', () {
      final two = computeOperatorMetrics(
        [entry('1', calledBy: 'a'), entry('2', calledBy: 'a')],
        ownerUids: {'o'},
      );
      expect(two.single.avgServiceMin, isNull);
      final three = computeOperatorMetrics(
        [
          entry('1', calledBy: 'a', serviceMin: 2),
          entry('2', calledBy: 'a', serviceMin: 4),
          entry('3', calledBy: 'a', serviceMin: 6),
          entry('4', calledBy: 'a', result: 'no_show', serviceMin: 60),
        ],
        ownerUids: {'o'},
      );
      expect(three.single.avgServiceMin, 4);
    });

    test('nota media so considera atendimentos do atendente', () {
      final stats = computeOperatorMetrics(
        [
          entry('1', calledBy: 'a'),
          entry('2', calledBy: 'b'),
          entry('3', calledBy: 'a', result: 'no_show'),
        ],
        ownerUids: {'o'},
        feedback: const [
          QueueFeedback(entryId: '1', rating: 5),
          QueueFeedback(entryId: '2', rating: 1),
          QueueFeedback(entryId: '3', rating: 1),
        ],
      );
      final a = stats.firstWhere((s) => s.attendantId == 'a');
      expect(a.feedback.count, 1);
      expect(a.feedback.average, 5);
    });

    test('calledBy vazio vira dono', () {
      final stats = computeOperatorMetrics(
        [entry('1', calledBy: '')],
        ownerUids: {'o'},
      );
      expect(stats.single.isOwner, isTrue);
    });

    test('sem calledAt ou finishedAt nao conta amostra', () {
      final stats = computeOperatorMetrics(
        [
          HistoryEntry(
            id: '1',
            ticket: 1,
            name: 'Ana',
            result: 'served',
            joinedAt: base,
            calledBy: 'a',
          ),
          HistoryEntry(
            id: '2',
            ticket: 1,
            name: 'Ana',
            result: 'served',
            joinedAt: base,
            calledAt: base,
            calledBy: 'a',
          ),
        ],
        ownerUids: {'o'},
      );
      expect(stats.single.served, 2);
      expect(stats.single.serviceSamples, 0);
    });

    test('duracao negativa e descartada', () {
      final stats = computeOperatorMetrics(
        [
          entry('1', calledBy: 'a', serviceMin: 2),
          entry('2', calledBy: 'a', serviceMin: 4),
          entry('3', calledBy: 'a', serviceMin: 6),
          entry('4', calledBy: 'a', serviceMin: -30),
        ],
        ownerUids: {'o'},
      );
      expect(stats.single.serviceSamples, 3);
      expect(stats.single.avgServiceMin, 4);
    });

    test('ownerUids vazio nao agrupa uid como dono', () {
      final stats = computeOperatorMetrics([
        entry('1', calledBy: 'o'),
        entry('2'),
      ]);
      expect(stats, hasLength(2));
    });

    test('donos de filas diferentes caem no mesmo balde', () {
      final stats = computeOperatorMetrics(
        [entry('1', calledBy: 'o1'), entry('2', calledBy: 'o2')],
        ownerUids: {'o1', 'o2'},
      );
      expect(stats.single.isOwner, isTrue);
      expect(stats.single.served, 2);
    });

    test('merge entre filas: 2 + 3 amostras dao media das 5', () {
      final stats = computeOperatorMetrics(
        [
          entry('a1', calledBy: 'a', serviceMin: 2),
          entry('a2', calledBy: 'a', serviceMin: 2),
          entry('b1', calledBy: 'a', serviceMin: 6),
          entry('b2', calledBy: 'a', serviceMin: 6),
          entry('b3', calledBy: 'a', serviceMin: 6),
        ],
        ownerUids: {'o'},
      );
      expect(stats.single.avgServiceMin, closeTo(4.4, 1e-9));
    });

    test('merge entre filas: 2 + 1 amostras somam 3 e liberam a media', () {
      final stats = computeOperatorMetrics(
        [
          entry('a1', calledBy: 'a'),
          entry('a2', calledBy: 'a'),
          entry('b1', calledBy: 'a'),
        ],
        ownerUids: {'o'},
      );
      expect(stats.single.served, 3);
      expect(stats.single.avgServiceMin, isNotNull);
    });

    test('merge entre filas: 1 + 1 amostras seguem sem media', () {
      final stats = computeOperatorMetrics(
        [entry('a1', calledBy: 'a'), entry('b1', calledBy: 'a')],
        ownerUids: {'o'},
      );
      expect(stats.single.avgServiceMin, isNull);
    });

    test('desconhecido ordena pelo nome exibido', () {
      final stats = computeOperatorMetrics(
        [entry('1', calledBy: 'zzz'), entry('2', calledBy: 'u2')],
        ownerUids: {'o'},
        names: const {'u2': 'Bia'},
        unknownName: 'ex-operador',
      );
      expect(stats.map((s) => s.attendantId), ['u2', 'zzz']);
    });

    test('empate de volume ordena por nome', () {
      final stats = computeOperatorMetrics(
        [entry('1', calledBy: 'u1'), entry('2', calledBy: 'u2')],
        ownerUids: {'o'},
        names: const {'u1': 'Zeca', 'u2': 'Bia'},
      );
      expect(stats.map((s) => s.attendantId), ['u2', 'u1']);
    });
  });
}
