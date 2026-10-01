import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Query, Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/history_entry.dart';
import '../models/queue.dart';
import '../models/queue_entry.dart';
import 'mirror.dart';
import 'operator_service.dart';

class QueueService {
  QueueService._();
  static final QueueService instance = QueueService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  String get currentUid => _uid;

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
    try {
      await _rtdb.ref('owners/$queueId').set({'ownerUid': _uid});
      await _rtdb.ref('queues/$queueId/meta').set({
        'nextTicket': 0,
        'serving': 0,
        'status': QueueStatus.open.value,
        'name': name,
        'description': description,
        'avgServiceMin': avgServiceMin,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (_) {
      try {
        await docRef.delete();
      } catch (_) {}
      rethrow;
    }

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

  Future<void> _ensureOwnerMirror(String queueId) async {
    final snap = await _rtdb.ref('owners/$queueId').get();
    final val = snap.value as Map<dynamic, dynamic>?;
    if (val == null || val['ownerUid'] != _uid) {
      await _rtdb.ref('owners/$queueId').set({'ownerUid': _uid});
    }
  }

  final Set<String> _mirrorChecked = {};

  Future<void> _ensureOwnerMirrorIfOwner(String queueId) async {
    final key = '$_uid/$queueId';
    if (_mirrorChecked.contains(key)) return;
    final doc = await _firestore.collection('queues').doc(queueId).get();
    if (doc.data()?['ownerId'] == _uid) {
      await _ensureOwnerMirror(queueId);
    }
    _mirrorChecked.add(key);
  }

  Future<void> ensureMirror(String queueId) async {
    final ownerSnap = await _rtdb.ref('owners/$queueId').get();
    final metaSnap = await _rtdb.ref('queues/$queueId/meta').get();
    final owner = ownerSnap.value as Map<dynamic, dynamic>?;
    final meta = metaSnap.value as Map<dynamic, dynamic>?;
    if (!mirrorNeedsRepair(owner, meta, _uid)) return;

    final doc = await _firestore.collection('queues').doc(queueId).get();
    final data = doc.data();
    if (data == null || data['ownerId'] != _uid) return;

    await _rtdb.ref('owners/$queueId').set({'ownerUid': _uid});
    if (meta == null) {
      final queue = Queue.fromDoc(queueId, data);
      await _rtdb.ref('queues/$queueId/meta').set({
        'nextTicket': 0,
        'serving': 0,
        'status': queue.status.value,
        'name': queue.name,
        'description': queue.description,
        'avgServiceMin': queue.avgServiceMin,
        'updatedAt': ServerValue.timestamp,
      });
    }
    _mirrorChecked.add('$_uid/$queueId');
  }

  Future<void> updateQueueStatus(String queueId, QueueStatus status) async {
    await _firestore.collection('queues').doc(queueId).update({
      'status': status.value,
    });
    await _ensureOwnerMirror(queueId);
    await _rtdb.ref('queues/$queueId/meta').update({
      'status': status.value,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> deleteQueue(String queueId) async {
    await _ensureOwnerMirror(queueId);
    await OperatorService.instance.deleteOperatorData(queueId);
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
    final entriesSnap = await _rtdb.ref('queues/$queueId/entries').get();
    final map = entriesSnap.value as Map<dynamic, dynamic>?;
    if (map != null) {
      for (final key in map.keys) {
        await _rtdb.ref('queues/$queueId/entries/$key').remove();
      }
    }
    await _rtdb.ref('queues/$queueId/meta').remove();
    await _rtdb.ref('tickets/$queueId').remove();
    await _rtdb.ref('owners/$queueId').remove();
  }

  Stream<Queue> watchQueue(String queueId) {
    return _firestore
        .collection('queues')
        .doc(queueId)
        .snapshots()
        .where((d) => d.exists && d.data() != null)
        .map((d) => Queue.fromDoc(d.id, d.data()!));
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

  Stream<List<HistoryEntry>> watchHistory(String queueId, {int limit = 200}) {
    return _firestore
        .collection('queues')
        .doc(queueId)
        .collection('history')
        .orderBy('finishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => HistoryEntry.fromDoc(d.id, d.data()))
              .toList(),
        );
  }

  Stream<int> watchWaitingCount(String queueId) {
    return watchEntries(queueId).map(
      (entries) => entries.where((e) => e.status == EntryStatus.waiting).length,
    );
  }

  Future<QueueEntry?> callNext(String queueId) async {
    final metaRef = _rtdb.ref('queues/$queueId/meta');
    final entriesRef = _rtdb.ref('queues/$queueId/entries');

    await _ensureOwnerMirrorIfOwner(queueId);
    final query = entriesRef.orderByChild('status').equalTo('waiting');
    final snap = await query.get();
    final map = snap.value as Map<dynamic, dynamic>?;
    if (map == null || map.isEmpty) return null;

    final candidates = map.entries.map((e) {
      return QueueEntry.fromSnapshot(e.key, e.value as Map<dynamic, dynamic>);
    }).toList()..sort((a, b) => a.ticket.compareTo(b.ticket));

    for (final candidate in candidates) {
      final claimed = await _claimEntry(entriesRef.child(candidate.id));
      if (claimed == null) continue;
      await _advanceServing(metaRef, claimed.ticket);
      return claimed;
    }
    return null;
  }

  Future<void> _advanceServing(DatabaseReference metaRef, int ticket) async {
    await metaRef.child('serving').runTransaction((current) {
      final serving = (current as num?)?.toInt() ?? 0;
      if (ticket <= serving) return Transaction.abort();
      return Transaction.success(ticket);
    }, applyLocally: false);
    await metaRef.update({'updatedAt': ServerValue.timestamp});
  }

  Future<QueueEntry?> _claimEntry(DatabaseReference entryRef) async {
    final uid = _uid;
    final now = DateTime.now().millisecondsSinceEpoch;
    final result = await entryRef.runTransaction((current) {
      if (current == null) return Transaction.success(null);
      final data = Map<Object?, Object?>.from(current as Map);
      if (data['status'] != EntryStatus.waiting.value) {
        return Transaction.abort();
      }
      data['status'] = EntryStatus.called.value;
      data['calledAt'] = now;
      data['operatorId'] = uid;
      return Transaction.success(data);
    }, applyLocally: false);

    final value = result.snapshot.value;
    if (!result.committed || value is! Map) return null;
    final entry = QueueEntry.fromSnapshot(result.snapshot.key!, value);
    if (entry.status != EntryStatus.called || entry.operatorId != uid) {
      return null;
    }
    return entry;
  }

  Future<void> _finishEntry(
    String queueId,
    QueueEntry entry,
    EntryStatus result,
  ) async {
    final entriesRef = _rtdb.ref('queues/$queueId/entries');
    await _ensureOwnerMirrorIfOwner(queueId);
    await entriesRef.child(entry.id).update({
      'status': result.value,
      'operatorId': _uid,
    });
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
          'calledBy': entry.operatorId,
          'operatorId': _uid,
          'finishedAt': FieldValue.serverTimestamp(),
        });
  }

  String queueJoinUrl(String queueId) => 'https://qio.web.app/q/$queueId';
}
