import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/services/queue_service.dart';

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
  late FakeDatabase rtdb;

  setUp(() => rtdb = FakeDatabase());

  Future<void> seed(
    FakeFirebaseFirestore fs,
    String id, {
    String owner = 'uid-1',
    String? group = 'g1',
    String status = 'open',
    bool deleting = false,
    bool withNotice = false,
  }) => fs.collection('queues').doc(id).set({
    'ownerId': owner,
    'name': 'Fila $id',
    'status': status,
    'groupId': ?group,
    if (deleting) 'deleting': true,
    if (withNotice) 'statusMessage': 'volto ja',
    if (withNotice) 'resumeAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
  });

  Future<Map<String, dynamic>> data(
    FakeFirebaseFirestore fs,
    String id,
  ) async => (await fs.collection('queues').doc(id).get()).data()!;

  QueueService svc(FakeFirebaseFirestore fs) =>
      QueueService.forTesting(fs, rtdb, FakeFirebaseAuth());

  test('touches only own, non-deleting queues of the group', () async {
    final fs = FakeFirebaseFirestore();
    await seed(fs, 'a');
    await seed(fs, 'b');
    await seed(fs, 'other-owner', owner: 'uid-2');
    await seed(fs, 'other-group', group: 'g2');
    await seed(fs, 'no-group', group: null);
    await seed(fs, 'gone', deleting: true);

    final result = await svc(fs).updateGroupStatus(
      'g1',
      QueueStatus.paused,
      message: ' volto ja ',
      resumeAt: DateTime.utc(2026, 1, 1, 12),
    );

    expect(result.total, 2);
    expect(result.updated, 2);
    expect(result.isComplete, isTrue);
    for (final id in ['a', 'b']) {
      final d = await data(fs, id);
      expect(d['status'], 'paused');
      expect(d['statusMessage'], 'volto ja');
      expect(d['resumeAt'], isA<Timestamp>());
    }
    for (final id in ['other-owner', 'other-group', 'no-group', 'gone']) {
      expect((await data(fs, id))['status'], 'open');
    }
    expect(rtdb.touched, isFalse);
  });

  test('reopening clears message and resumeAt', () async {
    final fs = FakeFirebaseFirestore();
    await seed(fs, 'a', status: 'paused', withNotice: true);
    await seed(fs, 'b', status: 'closed', withNotice: true);

    final result = await svc(fs).updateGroupStatus(
      'g1',
      QueueStatus.open,
      message: 'ignorada',
      resumeAt: DateTime.utc(2026, 1, 1),
    );

    expect(result.updated, 2);
    for (final id in ['a', 'b']) {
      final d = await data(fs, id);
      expect(d['status'], 'open');
      expect(d.containsKey('statusMessage'), isFalse);
      expect(d.containsKey('resumeAt'), isFalse);
    }
    expect(rtdb.touched, isFalse);
  });

  test('empty group returns an empty result', () async {
    final fs = FakeFirebaseFirestore();
    final result = await svc(fs).updateGroupStatus('g1', QueueStatus.closed);
    expect(result.isEmpty, isTrue);
    expect(result.failed, 0);
  });

  test('more than 450 queues are written in chunks', () async {
    final fs = _FlakyFirestore();
    for (var i = 0; i < 460; i++) {
      await seed(fs, 'q$i');
    }
    final result = await svc(fs).updateGroupStatus('g1', QueueStatus.closed);
    expect(fs.batches, 2);
    expect(result.total, 460);
    expect(result.updated, 460);
    expect((await data(fs, 'q459'))['status'], 'closed');
    expect(rtdb.touched, isFalse);
  });

  test('a failed chunk is reported as a partial result', () async {
    final fs = _FlakyFirestore(failOn: {2});
    for (var i = 0; i < 460; i++) {
      await seed(fs, 'q$i');
    }
    final result = await svc(fs).updateGroupStatus('g1', QueueStatus.paused);
    expect(result.total, 460);
    expect(result.updated, 450);
    expect(result.failed, 10);
    expect(result.isPartial, isTrue);
    final paused = (await fs.collection('queues').get()).docs.where(
      (d) => d.data()['status'] == 'paused',
    );
    expect(paused.length, 450);
  });

  test('every chunk failing yields zero updated, not an exception', () async {
    final fs = _FlakyFirestore(failOn: {1});
    await seed(fs, 'a');
    final result = await svc(fs).updateGroupStatus('g1', QueueStatus.paused);
    expect(result.updated, 0);
    expect(result.isPartial, isFalse);
    expect(result.isComplete, isFalse);
  });
}
