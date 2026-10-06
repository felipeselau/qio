import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Query, Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/history_entry.dart';
import '../models/queue.dart';
import '../models/queue_entry.dart';
import '../models/queue_feedback.dart';
import '../models/queue_schedule.dart';
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
    int maxWaiting = 0,
  }) async {
    final now = DateTime.now();
    final docRef = await _firestore.collection('queues').add({
      'ownerId': _uid,
      'name': name,
      'description': description,
      'status': QueueStatus.open.value,
      'avgServiceMin': avgServiceMin,
      'maxWaiting': maxWaiting,
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
        'maxWaiting': maxWaiting,
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

  Future<void> updateQueueStatus(
    String queueId,
    QueueStatus status, {
    String? message,
    DateTime? resumeAt,
  }) async {
    final keepNotice = status != QueueStatus.open;
    final text = keepNotice && message != null && message.trim().isNotEmpty
        ? message.trim()
        : null;
    final until = keepNotice ? resumeAt : null;
    await _firestore.collection('queues').doc(queueId).update({
      'status': status.value,
      'statusMessage': text ?? FieldValue.delete(),
      'resumeAt': until != null
          ? Timestamp.fromDate(until)
          : FieldValue.delete(),
    });
    await _ensureOwnerMirror(queueId);
    await _rtdb.ref('queues/$queueId/meta').update({
      'status': status.value,
      'statusMessage': text,
      'resumeAt': until?.millisecondsSinceEpoch,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> updateSchedule(String queueId, QueueSchedule? schedule) async {
    await _firestore.collection('queues').doc(queueId).update({
      'schedule': schedule != null && schedule.enabled
          ? schedule.toMap()
          : FieldValue.delete(),
      'scheduleLastDesired': FieldValue.delete(),
    });
  }

  Future<void> updateMaxWaiting(String queueId, int maxWaiting) async {
    await _firestore.collection('queues').doc(queueId).update({
      'maxWaiting': maxWaiting,
    });
    await _ensureOwnerMirror(queueId);
    await _rtdb.ref('queues/$queueId/meta').update({
      'maxWaiting': maxWaiting,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> deleteQueue(String queueId) async {
    await _ensureOwnerMirror(queueId);
    final entriesSnap = await _rtdb.ref('queues/$queueId/entries').get();
    final entries = entriesSnap.value as Map<dynamic, dynamic>?;
    if (entries != null) {
      for (final key in entries.keys) {
        await _rtdb.ref('queues/$queueId/entries/$key').remove();
      }
    }
    await _rtdb.ref('queues/$queueId/public').remove();
    await _rtdb.ref('queues/$queueId/meta').remove();
    await _rtdb.ref('tickets/$queueId').remove();
    await OperatorService.instance.deleteOperatorData(queueId);
    await _rtdb.ref('owners/$queueId').remove();
    final historySnap = await _firestore
        .collection('queues')
        .doc(queueId)
        .collection('history')
        .get();
    final feedbackSnap = await _firestore
        .collection('queues')
        .doc(queueId)
        .collection('feedback')
        .get();
    final batch = _firestore.batch();
    for (final doc in historySnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in feedbackSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('queues').doc(queueId));
    await batch.commit();
  }

  Stream<Queue> watchQueue(String queueId) {
    return _firestore
        .collection('queues')
        .doc(queueId)
        .snapshots()
        .where((d) => d.exists && d.data() != null)
        .map((d) => Queue.fromDoc(d.id, d.data()!));
  }

  Future<({Queue queue, bool isOwner})?> resolveAccess(String queueId) async {
    final uid = _uid;
    try {
      final doc = _firestore.collection('queues').doc(queueId);
      final operator = await doc.collection('operators').doc(uid).get();
      final snap = await doc.get();
      if (!snap.exists || snap.data() == null) return null;
      final queue = Queue.fromDoc(snap.id, snap.data()!);
      if (queue.ownerId == uid) return (queue: queue, isOwner: true);
      if (operator.exists) return (queue: queue, isOwner: false);
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'not-found') return null;
      rethrow;
    }
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
          }).toList()..sort(QueueEntry.compareInQueue);
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

  Future<List<HistoryEntry>> fetchHistory(
    String queueId, {
    int limit = 500,
  }) async {
    final snap = await _firestore
        .collection('queues')
        .doc(queueId)
        .collection('history')
        .orderBy('finishedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => HistoryEntry.fromDoc(d.id, d.data())).toList();
  }

  Stream<List<QueueFeedback>> watchFeedback(String queueId) {
    return _firestore
        .collection('queues')
        .doc(queueId)
        .collection('feedback')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => QueueFeedback.fromDoc(d.id, d.data()))
              .toList(),
        );
  }

  Stream<bool> watchConnection() {
    return _rtdb
        .ref('.info/connected')
        .onValue
        .map((event) => event.snapshot.value == true);
  }

  Stream<int> watchWaitingCount(String queueId) {
    return _rtdb.ref('queues/$queueId/public').onValue.map((event) {
      final map = event.snapshot.value as Map<dynamic, dynamic>?;
      if (map == null) return 0;
      return map.values
          .where((v) => v is Map && v['status'] == EntryStatus.waiting.value)
          .length;
    });
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
    }).toList()..sort(QueueEntry.compareInQueue);

    for (final candidate in candidates) {
      final claimed = await _claimEntry(entriesRef.child(candidate.id));
      if (claimed == null) continue;
      await _advanceServing(metaRef, claimed.ticket);
      return claimed;
    }
    return null;
  }

  Future<QueueEntry?> callEntry(String queueId, QueueEntry entry) async {
    await _ensureOwnerMirrorIfOwner(queueId);
    final claimed = await _claimEntry(
      _rtdb.ref('queues/$queueId/entries/${entry.id}'),
    );
    if (claimed == null) return null;
    await _advanceServing(_rtdb.ref('queues/$queueId/meta'), claimed.ticket);
    return claimed;
  }

  Future<void> recallEntry(String queueId, QueueEntry entry) async {
    await _ensureOwnerMirrorIfOwner(queueId);
    await _rtdb.ref('queues/$queueId/entries/${entry.id}').update({
      'recalledAt': ServerValue.timestamp,
      'recalls': ServerValue.increment(1),
    });
  }

  Future<void> moveEntryToEnd(String queueId, QueueEntry entry) async {
    await _ensureOwnerMirrorIfOwner(queueId);
    await _rtdb.ref('queues/$queueId/entries/${entry.id}').update({
      'order': ServerValue.timestamp,
      'skips': ServerValue.increment(1),
    });
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
    await _archiveEntry(queueId, entry, result);
    await entriesRef.child(entry.id).update({
      'status': result.value,
      'operatorId': _uid,
    });
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
    try {
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
            if (entry.recalls > 0) 'recalls': entry.recalls,
            if (entry.skips > 0) 'skips': entry.skips,
          });
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }
  }

  String queueJoinUrl(String queueId) => 'https://qio.web.app/q/$queueId';
}
