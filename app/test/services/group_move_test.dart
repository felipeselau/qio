import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/group_service.dart';

import '../helpers/fake_rtdb.dart';

class _FailingBatch implements WriteBatch {
  _FailingBatch(this.real);

  final WriteBatch real;

  @override
  Future<void> commit() async =>
      throw FirebaseException(plugin: 'firestore', code: 'unavailable');

  @override
  void update<T>(DocumentReference<T> document, T data) =>
      real.update(document, data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FlakyFirestore extends FakeFirebaseFirestore {
  _FlakyFirestore({this.failOn = const {}});

  final Set<int> failOn;
  int batches = 0;

  @override
  WriteBatch batch() {
    batches++;
    final real = super.batch();
    return failOn.contains(batches) ? _FailingBatch(real) : real;
  }
}

void main() {
  Future<void> seed(
    FakeFirebaseFirestore fs,
    String id, {
    String owner = 'uid-1',
    String? group,
    bool deleting = false,
  }) => fs.collection('queues').doc(id).set({
    'ownerId': owner,
    'name': 'Fila $id',
    'groupId': ?group,
    if (deleting) 'deleting': true,
  });

  GroupService svc(FakeFirebaseFirestore fs) =>
      GroupService.forTesting(fs, FakeFirebaseAuth());

  Future<Map<String, dynamic>> data(
    FakeFirebaseFirestore fs,
    String id,
  ) async => (await fs.collection('queues').doc(id).get()).data()!;

  test('moves only the owner queues that were asked for', () async {
    final fs = FakeFirebaseFirestore();
    await seed(fs, 'a');
    await seed(fs, 'b', group: 'g0');
    await seed(fs, 'c');
    await seed(fs, 'foreign', owner: 'uid-2');
    await seed(fs, 'gone', deleting: true);

    final result = await svc(
      fs,
    ).setQueuesGroup(['a', 'b', 'foreign', 'gone', 'missing'], 'g1');

    expect(result.total, 2);
    expect(result.updated, 2);
    expect(result.isComplete, isTrue);
    expect((await data(fs, 'a'))['groupId'], 'g1');
    expect((await data(fs, 'b'))['groupId'], 'g1');
    expect((await data(fs, 'c')).containsKey('groupId'), isFalse);
    expect((await data(fs, 'foreign')).containsKey('groupId'), isFalse);
    expect((await data(fs, 'gone')).containsKey('groupId'), isFalse);
  });

  test('null group removes groupId', () async {
    final fs = FakeFirebaseFirestore();
    await seed(fs, 'a', group: 'g1');
    final result = await svc(fs).setQueuesGroup(['a'], null);
    expect(result.updated, 1);
    expect((await data(fs, 'a')).containsKey('groupId'), isFalse);
  });

  test('empty selection does nothing', () async {
    final fs = _FlakyFirestore();
    final result = await svc(fs).setQueuesGroup(const [], 'g1');
    expect(result.isEmpty, isTrue);
    expect(fs.batches, 0);
  });

  test('more than 450 queues are split into chunks', () async {
    final fs = _FlakyFirestore();
    final ids = [for (var i = 0; i < 1000; i++) 'q$i'];
    for (final id in ids) {
      await seed(fs, id);
    }
    await seed(fs, 'foreign', owner: 'uid-2');
    final result = await svc(fs).setQueuesGroup([...ids, 'foreign'], 'g1');
    expect(fs.batches, 3);
    expect(result.total, 1000);
    expect(result.updated, 1000);
    expect((await data(fs, 'q999'))['groupId'], 'g1');
    expect((await data(fs, 'foreign')).containsKey('groupId'), isFalse);
  });

  test(
    'a failed chunk is reported as partial and the others still run',
    () async {
      final fs = _FlakyFirestore(failOn: {2});
      final ids = [for (var i = 0; i < 1000; i++) 'q$i'];
      for (final id in ids) {
        await seed(fs, id);
      }
      final result = await svc(fs).setQueuesGroup(ids, 'g1');
      expect(fs.batches, 3);
      expect(result.total, 1000);
      expect(result.updated, 550);
      expect(result.failed, 450);
      expect(result.isPartial, isTrue);
      final grouped = (await fs.collection('queues').get()).docs
          .where((d) => d.data()['groupId'] == 'g1')
          .length;
      expect(grouped, 550);
    },
  );

  test('every chunk failing is neither partial nor complete', () async {
    final fs = _FlakyFirestore(failOn: {1});
    await seed(fs, 'a');
    final result = await svc(fs).setQueuesGroup(['a'], 'g1');
    expect(result.updated, 0);
    expect(result.isPartial, isFalse);
    expect(result.isComplete, isFalse);
  });
}
