import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/operator.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_slot.dart';
import 'package:qio_app/services/operator_service.dart';
import 'package:qio_app/services/queue_service.dart';

import '../helpers/fake_rtdb.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FakeDatabase rtdb;
  late QueueService service;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    rtdb = FakeDatabase();
    service = QueueService.forTesting(firestore, rtdb, FakeFirebaseAuth());
    await firestore.collection('queues').doc('q1').set({
      'ownerId': 'uid-1',
      'name': 'Fila',
      'description': null,
      'status': 'open',
      'avgServiceMin': 10,
      'maxWaiting': 0,
    });
  });

  Future<Map<String, dynamic>> doc() async =>
      (await firestore.collection('queues').doc('q1').get()).data()!;

  group('setters escrevem so no Firestore', () {
    test('updateQueueStatus', () async {
      await service.updateQueueStatus(
        'q1',
        QueueStatus.paused,
        message: ' volto ja ',
        resumeAt: DateTime.utc(2026, 1, 1, 12),
      );
      final d = await doc();
      expect(d['status'], 'paused');
      expect(d['statusMessage'], 'volto ja');
      expect(d['resumeAt'], isA<Timestamp>());
      await service.updateQueueStatus('q1', QueueStatus.open);
      final reopened = await doc();
      expect(reopened['status'], 'open');
      expect(reopened.containsKey('statusMessage'), isFalse);
      expect(reopened.containsKey('resumeAt'), isFalse);
      expect(rtdb.touched, isFalse);
    });

    test('updateQueueInfo', () async {
      await service.updateQueueInfo(
        'q1',
        name: 'Nova',
        description: 'desc',
        avgServiceMin: 15,
      );
      final d = await doc();
      expect(d['name'], 'Nova');
      expect(d['description'], 'desc');
      expect(d['avgServiceMin'], 15);
      expect(rtdb.touched, isFalse);
    });

    test('updateQueueInfo invalido lanca FormatException', () async {
      await expectLater(
        service.updateQueueInfo(
          'q1',
          name: '',
          description: null,
          avgServiceMin: 15,
        ),
        throwsFormatException,
      );
      expect((await doc())['name'], 'Fila');
      expect(rtdb.touched, isFalse);
    });

    test('updateQueueInfo de outro dono lanca StateError', () async {
      await firestore.collection('queues').doc('q1').update({'ownerId': 'x'});
      await expectLater(
        service.updateQueueInfo(
          'q1',
          name: 'Nova',
          description: null,
          avgServiceMin: 15,
        ),
        throwsStateError,
      );
      expect(rtdb.touched, isFalse);
    });

    test('updateMaxWaiting e updateBrandColor', () async {
      await service.updateMaxWaiting('q1', 30);
      await service.updateBrandColor('q1', '#112233');
      expect((await doc())['maxWaiting'], 30);
      expect((await doc())['brandColor'], '#112233');
      await service.updateBrandColor('q1', null);
      expect((await doc()).containsKey('brandColor'), isFalse);
      expect(rtdb.touched, isFalse);
    });

    test('updateModeAndSlots ordena e grava so no Firestore', () async {
      await service.updateModeAndSlots('q1', QueueMode.schedule, [
        const QueueSlot(id: 'b', start: '10:00', capacity: 2),
        const QueueSlot(id: 'a', start: '09:00', capacity: 3),
      ]);
      final d = await doc();
      expect(d['mode'], 'schedule');
      expect((d['slots'] as List).map((s) => s['id']), ['a', 'b']);
      expect(rtdb.touched, isFalse);
    });
  });

  group('createQueue e ensureMirror continuam escrevendo no RTDB', () {
    test('createQueue grava owners e meta iniciais', () async {
      final queue = await service.createQueue(name: 'Nova', maxWaiting: 5);
      expect(
        rtdb.writes,
        containsAll(['set:owners/${queue.id}', 'set:queues/${queue.id}/meta']),
      );
      expect(rtdb.values['owners/${queue.id}'], {'ownerUid': 'uid-1'});
      final meta = rtdb.values['queues/${queue.id}/meta']! as Map;
      expect(meta['name'], 'Nova');
      expect(meta['maxWaiting'], 5);
      expect(meta['status'], 'open');
    });

    test('duplicateQueue herda o write inicial do createQueue', () async {
      final copy = await service.duplicateQueue('q1', name: 'Fila (copia)');
      expect(rtdb.writes, contains('set:queues/${copy.id}/meta'));
    });

    test('ensureMirror repara espelho ausente', () async {
      await service.ensureMirror('q1');
      expect(rtdb.writes, contains('set:owners/q1'));
      expect(rtdb.writes, contains('set:queues/q1/meta'));
    });

    test('ensureMirror recria meta com limite, cor, logo e aviso', () async {
      await firestore.collection('queues').doc('q1').update({
        'status': 'paused',
        'maxWaiting': 7,
        'brandColor': '#112233',
        'logoUrl': 'https://firebasestorage.googleapis.com/x',
        'statusMessage': 'volto ja',
        'resumeAt': Timestamp.fromMillisecondsSinceEpoch(5000),
      });
      await service.ensureMirror('q1');
      final meta = rtdb.values['queues/q1/meta']! as Map;
      expect(meta['maxWaiting'], 7);
      expect(meta['brandColor'], '#112233');
      expect(meta['logoUrl'], 'https://firebasestorage.googleapis.com/x');
      expect(meta['statusMessage'], 'volto ja');
      expect(meta['resumeAt'], 5000);
    });

    test('ensureMirror nao escreve quando o espelho esta em dia', () async {
      rtdb.values['owners/q1'] = {'ownerUid': 'uid-1'};
      rtdb.values['queues/q1/meta'] = {
        'name': 'Fila',
        'description': null,
        'avgServiceMin': 10,
      };
      await service.ensureMirror('q1');
      expect(rtdb.writes, isEmpty);
    });
  });

  group('OperatorService', () {
    late OperatorService operators;

    setUp(() {
      operators = OperatorService.forTesting(
        firestore,
        rtdb,
        FakeFirebaseAuth(),
      );
    });

    test('aprovar e remover nao tocam o RTDB', () async {
      final request = OperatorRequest(
        uid: 'op1',
        queueId: 'q1',
        queueName: 'Fila',
        status: OperatorRequestStatus.pending,
      );
      await firestore
          .collection('queues')
          .doc('q1')
          .collection('operatorRequests')
          .doc('op1')
          .set({'uid': 'op1', 'status': 'pending'});
      await operators.approveOperatorRequest('q1', request);
      expect((await operators.fetchOperators('q1')).map((o) => o.uid), ['op1']);
      await operators.removeOperator('q1', 'op1');
      expect(await operators.fetchOperators('q1'), isEmpty);
      expect(rtdb.touched, isFalse);
    });

    test('syncOperatorMirror (reparo) escreve quando diverge', () async {
      await firestore
          .collection('queues')
          .doc('q1')
          .collection('operators')
          .doc('op1')
          .set({'uid': 'op1'});
      await operators.syncOperatorMirror('q1');
      expect(rtdb.values['queues/q1/operatorUids'], {'op1': true});
    });

    test('syncOperatorMirror ignora fila de outro dono', () async {
      await firestore.collection('queues').doc('q1').update({'ownerId': 'x'});
      await operators.syncOperatorMirror('q1');
      expect(rtdb.touched, isFalse);
    });

    test('syncOperatorMirror nao escreve quando esta em dia', () async {
      await firestore
          .collection('queues')
          .doc('q1')
          .collection('operators')
          .doc('op1')
          .set({'uid': 'op1'});
      rtdb.values['owners/q1'] = {'ownerUid': 'uid-1'};
      rtdb.values['queues/q1/operatorUids'] = {'op1': true};
      await operators.syncOperatorMirror('q1');
      expect(rtdb.writes, isEmpty);
    });
  });
}
