import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/queue.dart';
import '../models/queue_entry.dart';

class QueueService {
  QueueService._();
  static final QueueService instance = QueueService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  Stream<List<Queue>> watchOwnerQueues() {
    return _firestore
        .collection('queues')
        .where('ownerId', isEqualTo: _uid)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Queue.fromDoc(d.id, d.data())).toList(),
        );
  }

  Future<Queue> createQueue({
    required String name,
    String? description,
    int avgServiceMin = 10,
  }) async {
    final now = DateTime.now();
    final docRef = await _firestore.collection('queues').add({
      'ownerId': _uid,
      'name': name,
      'description': description,
      'status': QueueStatus.open.value,
      'avgServiceMin': avgServiceMin,
      'createdAt': Timestamp.fromDate(now),
    });

    final queueId = docRef.id;
    await _rtdb.ref('owners/$queueId').set({'ownerUid': _uid});
    await _rtdb.ref('queues/$queueId/meta').set({
      'nextTicket': 0,
      'serving': 0,
      'status': QueueStatus.open.value,
      'name': name,
      'updatedAt': ServerValue.timestamp,
    });

    return Queue(
      id: queueId,
      ownerId: _uid,
      name: name,
      description: description,
      status: QueueStatus.open,
      avgServiceMin: avgServiceMin,
      createdAt: now,
    );
  }

  Future<void> updateQueueStatus(String queueId, QueueStatus status) async {
    await _firestore.collection('queues').doc(queueId).update({
      'status': status.value,
    });
    await _rtdb.ref('queues/$queueId/meta').update({
      'status': status.value,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> deleteQueue(String queueId) async {
    final historySnap = await _firestore
        .collection('queues')
        .doc(queueId)
        .collection('history')
        .get();
    final batch = _firestore.batch();
    for (final doc in historySnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('queues').doc(queueId));
    await batch.commit();
    await _rtdb.ref('queues/$queueId').remove();
    await _rtdb.ref('owners/$queueId').remove();
  }

  Stream<Queue> watchQueue(String queueId) {
    return _firestore
        .collection('queues')
        .doc(queueId)
        .snapshots()
        .map((d) => Queue.fromDoc(d.id, d.data() as Map<String, dynamic>));
  }

  Stream<List<QueueEntry>> watchEntries(String queueId) {
    return _rtdb
        .ref('queues/$queueId/entries')
        .orderByChild('ticket')
        .onValue
        .map((event) {
          final map = event.snapshot.value as Map<dynamic, dynamic>?;
          if (map == null) return <QueueEntry>[];
          return map.entries.map((e) {
            return QueueEntry.fromSnapshot(
              e.key,
              e.value as Map<dynamic, dynamic>,
            );
          }).toList()..sort((a, b) => a.ticket.compareTo(b.ticket));
        });
  }

  Stream<int> watchWaitingCount(String queueId) {
    return watchEntries(queueId).map(
      (entries) => entries.where((e) => e.status == EntryStatus.waiting).length,
    );
  }

  Future<QueueEntry?> callNext(String queueId) async {
    final metaRef = _rtdb.ref('queues/$queueId/meta');
    final entriesRef = _rtdb.ref('queues/$queueId/entries');

    final now = DateTime.now().millisecondsSinceEpoch;
    final query = entriesRef.orderByChild('status').equalTo('waiting');
    final snap = await query.get();
    final map = snap.value as Map<dynamic, dynamic>?;
    if (map == null || map.isEmpty) return null;

    final entries = map.entries.map((e) {
      return QueueEntry.fromSnapshot(e.key, e.value as Map<dynamic, dynamic>);
    }).toList()..sort((a, b) => a.ticket.compareTo(b.ticket));

    final next = entries.first;
    await entriesRef.child(next.id).update({
      'status': EntryStatus.called.value,
      'calledAt': now,
    });
    await metaRef.update({
      'serving': next.ticket,
      'updatedAt': ServerValue.timestamp,
    });

    return next;
  }

  Future<void> _finishEntry(
    String queueId,
    QueueEntry entry,
    EntryStatus result,
  ) async {
    final entriesRef = _rtdb.ref('queues/$queueId/entries');
    await entriesRef.child(entry.id).update({'status': result.value});
    await _archiveEntry(queueId, entry, result);
    await entriesRef.child(entry.id).remove();
  }

  Future<void> markServed(String queueId, QueueEntry entry) async {
    await _finishEntry(queueId, entry, EntryStatus.served);
  }

  Future<void> markNoShow(String queueId, QueueEntry entry) async {
    await _finishEntry(queueId, entry, EntryStatus.noShow);
  }

  Future<void> _archiveEntry(
    String queueId,
    QueueEntry entry,
    EntryStatus result,
  ) async {
    await _firestore
        .collection('queues')
        .doc(queueId)
        .collection('history')
        .doc(entry.id)
        .set({
          'ticket': entry.ticket,
          'name': entry.name,
          'phone': entry.phone,
          'result': result.value,
          'joinedAt': Timestamp.fromDate(entry.joinedAt),
          'calledAt': entry.calledAt != null
              ? Timestamp.fromDate(entry.calledAt!)
              : null,
          'finishedAt': FieldValue.serverTimestamp,
        });
  }

  String queueJoinUrl(String queueId) => 'https://qio.web.app/q/$queueId';
}
