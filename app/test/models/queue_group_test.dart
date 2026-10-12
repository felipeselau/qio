import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_group.dart';
import 'package:qio_app/services/group_service.dart';

QueueGroup grp(String id, String name, [int ms = 0]) => QueueGroup(
  id: id,
  name: name,
  createdAt: DateTime.fromMillisecondsSinceEpoch(ms),
);

Queue queue(String? groupId) => Queue(
  id: 'q',
  ownerId: 'o',
  name: 'Fila',
  createdAt: DateTime(2026),
  groupId: groupId,
);

void main() {
  group('QueueGroup color e order', () {
    test('doc legado sem os campos', () {
      final g = QueueGroup.fromDoc('g', {'name': 'A'});
      expect(g.colorHex, isNull);
      expect(g.order, isNull);
      expect(g.color, isNull);
    });

    test('lê cor da paleta e order', () {
      final g = QueueGroup.fromDoc('g', {
        'name': 'A',
        'colorHex': '#0f766e',
        'order': 3,
      });
      expect(g.colorHex, '#0F766E');
      expect(g.order, 3);
      expect(g.color, isNotNull);
    });

    test('ignora cor fora da paleta e order fora da faixa', () {
      for (final bad in ['#123456', 'red', 5, null]) {
        expect(QueueGroup.fromDoc('g', {'colorHex': bad}).colorHex, isNull);
      }
      for (final bad in [-1, 1001, '2', null]) {
        expect(QueueGroup.fromDoc('g', {'order': bad}).order, isNull);
      }
    });
  });

  group('sortGroups por order', () {
    QueueGroup o(String id, String name, int? order) =>
        QueueGroup(id: id, name: name, createdAt: DateTime(2026), order: order);

    test('order primeiro, nulos por último e depois nome', () {
      final sorted = sortGroups([
        o('1', 'Zeta', null),
        o('2', 'Beta', 1),
        o('3', 'Alfa', null),
        o('4', 'Omega', 0),
      ]);
      expect(sorted.map((g) => g.id), ['4', '2', '3', '1']);
    });

    test('order igual desempata pelo nome', () {
      final sorted = sortGroups([o('1', 'b', 2), o('2', 'a', 2)]);
      expect(sorted.map((g) => g.id), ['2', '1']);
    });
  });

  group('QueueGroup.fromDoc', () {
    test('parses name and Timestamp', () {
      final date = DateTime(2026, 3, 1, 9);
      final g = QueueGroup.fromDoc('g1', {
        'name': 'Loja Centro',
        'createdAt': Timestamp.fromDate(date),
      });
      expect(g.id, 'g1');
      expect(g.name, 'Loja Centro');
      expect(g.createdAt, date);
    });

    test('tolerates missing fields', () {
      final g = QueueGroup.fromDoc('g2', {});
      expect(g.name, '');
      expect(g.createdAt.millisecondsSinceEpoch, 0);
    });
  });

  group('resolveGroupId', () {
    final groups = [grp('a', 'A'), grp('b', 'B')];

    test('returns the id when the group exists', () {
      expect(resolveGroupId(queue('a'), groups), 'a');
    });

    test('orphan groupId resolves to no group', () {
      expect(resolveGroupId(queue('gone'), groups), isNull);
    });

    test('null or empty groupId resolves to no group', () {
      expect(resolveGroupId(queue(null), groups), isNull);
      expect(resolveGroupId(queue(''), groups), isNull);
    });
  });

  group('sortGroups', () {
    test('sorts by name ignoring case, then by creation', () {
      final sorted = sortGroups([
        grp('1', 'beta', 5),
        grp('2', 'Alfa', 9),
        grp('3', 'alfa', 1),
      ]);
      expect(sorted.map((g) => g.id), ['3', '2', '1']);
    });
  });

  group('sortGroups empty', () {
    test('returns an empty list', () {
      expect(sortGroups(const []), isEmpty);
    });
  });

  group('chunkList', () {
    test('splits into batches of at most the limit, preserving order', () {
      final items = List<int>.generate(1000, (i) => i);
      final chunks = chunkList(items, groupBatchLimit);
      expect(chunks.map((c) => c.length), [450, 450, 100]);
      expect(chunks.expand((c) => c).toList(), items);
    });

    test('exact multiple and empty input', () {
      expect(chunkList(List<int>.filled(900, 0), groupBatchLimit).length, 2);
      expect(chunkList(<int>[], groupBatchLimit), isEmpty);
      expect(chunkList([1, 2, 3], groupBatchLimit), [
        [1, 2, 3],
      ]);
    });

    test('limit stays below the Firestore batch cap', () {
      expect(groupBatchLimit, lessThanOrEqualTo(450));
    });
  });

  group('throwGroupError', () {
    test('maps permission-denied to GroupPermissionDeniedException', () {
      expect(
        () => throwGroupError(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
          StackTrace.current,
        ),
        throwsA(isA<GroupPermissionDeniedException>()),
      );
    });

    test('rethrows other errors untouched', () {
      expect(
        () => throwGroupError(StateError('x'), StackTrace.current),
        throwsStateError,
      );
    });
  });
}
