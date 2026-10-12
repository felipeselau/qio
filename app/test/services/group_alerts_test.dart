import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/alerts_config.dart';
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

const _config = AlertsConfig(
  enabled: true,
  maxWaitMin: 20,
  idleMin: 10,
  cooldownMin: 60,
);

void main() {
  Future<void> seed(
    FakeFirebaseFirestore fs,
    String id, {
    String owner = 'uid-1',
    String? group = 'g1',
    bool deleting = false,
    Map<String, dynamic>? alertState,
    Map<String, dynamic>? alerts,
  }) => fs.collection('queues').doc(id).set({
    'ownerId': owner,
    'name': 'Fila $id',
    'groupId': ?group,
    'alerts': ?alerts,
    'alertState': ?alertState,
    if (deleting) 'deleting': true,
  });

  QueueService svc(FakeFirebaseFirestore fs) =>
      QueueService.forTesting(fs, FakeDatabase(), FakeFirebaseAuth());

  Future<Map<String, dynamic>> data(
    FakeFirebaseFirestore fs,
    String id,
  ) async => (await fs.collection('queues').doc(id).get()).data()!;

  test('copies alerts only to own, non-deleting queues of the group', () async {
    final fs = FakeFirebaseFirestore();
    await seed(fs, 'a');
    await seed(fs, 'b', alerts: {'enabled': false, 'cooldownMin': 30});
    await seed(fs, 'other-owner', owner: 'uid-2');
    await seed(fs, 'other-group', group: 'g2');
    await seed(fs, 'no-group', group: null);
    await seed(fs, 'gone', deleting: true);

    final result = await svc(fs).applyGroupAlerts('g1', _config);

    expect(result.total, 2);
    expect(result.updated, 2);
    for (final id in ['a', 'b']) {
      expect((await data(fs, id))['alerts'], _config.toMap());
    }
    for (final id in ['other-owner', 'other-group', 'no-group', 'gone']) {
      expect((await data(fs, id)).containsKey('alerts'), isFalse);
    }
  });

  test('does not touch alertState', () async {
    final fs = FakeFirebaseFirestore();
    final state = {'waitAt': 123, 'idleAt': 456};
    await seed(fs, 'a', alertState: state);
    await svc(fs).applyGroupAlerts('g1', _config);
    expect((await data(fs, 'a'))['alertState'], state);
  });

  test('copies a disabled config as is', () async {
    final fs = FakeFirebaseFirestore();
    await seed(fs, 'a', alerts: {'enabled': true, 'cooldownMin': 30});
    const off = AlertsConfig();
    final result = await svc(fs).applyGroupAlerts('g1', off);
    expect(result.updated, 1);
    expect((await data(fs, 'a'))['alerts'], off.toMap());
  });

  test('rejects an invalid config before reading', () async {
    final fs = _FlakyFirestore();
    await seed(fs, 'a');
    expect(
      () => svc(fs).applyGroupAlerts('g1', const AlertsConfig(enabled: true)),
      throwsFormatException,
    );
    expect(fs.batches, 0);
    expect((await data(fs, 'a')).containsKey('alerts'), isFalse);
  });

  test('empty group returns an empty result', () async {
    final result = await svc(
      FakeFirebaseFirestore(),
    ).applyGroupAlerts('g1', _config);
    expect(result.isEmpty, isTrue);
  });

  test('more than 450 queues are split into chunks', () async {
    final fs = _FlakyFirestore();
    for (var i = 0; i < 1000; i++) {
      await seed(fs, 'q$i');
    }
    final result = await svc(fs).applyGroupAlerts('g1', _config);
    expect(fs.batches, 3);
    expect(result.total, 1000);
    expect(result.isComplete, isTrue);
    expect((await data(fs, 'q999'))['alerts'], _config.toMap());
  });

  test('a failed chunk is reported as partial', () async {
    final fs = _FlakyFirestore(failOn: {2});
    for (var i = 0; i < 1000; i++) {
      await seed(fs, 'q$i');
    }
    final result = await svc(fs).applyGroupAlerts('g1', _config);
    expect(fs.batches, 3);
    expect(result.total, 1000);
    expect(result.updated, 550);
    expect(result.isPartial, isTrue);
  });
}
