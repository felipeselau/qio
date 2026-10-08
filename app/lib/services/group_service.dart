import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/queue_group.dart';

class GroupLimitReachedException implements Exception {
  const GroupLimitReachedException();
}

class GroupPermissionDeniedException implements Exception {
  const GroupPermissionDeniedException();
}

Never throwGroupError(Object error, StackTrace stack) {
  if (error is FirebaseException && error.code == 'permission-denied') {
    Error.throwWithStackTrace(const GroupPermissionDeniedException(), stack);
  }
  Error.throwWithStackTrace(error, stack);
}

const groupBatchLimit = 450;

List<List<T>> chunkList<T>(List<T> items, int size) => [
  for (var i = 0; i < items.length; i += size)
    items.sublist(i, i + size > items.length ? items.length : i + size),
];

List<QueueGroup> sortGroups(Iterable<QueueGroup> groups) {
  final sorted = [...groups];
  sorted.sort((a, b) {
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return byName != 0 ? byName : a.createdAt.compareTo(b.createdAt);
  });
  return sorted;
}

class GroupService {
  GroupService._();
  static final GroupService instance = GroupService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('owners').doc(_uid).collection('groups');

  Stream<List<QueueGroup>> watchGroups() {
    return _groups.snapshots().map(
      (snap) =>
          sortGroups(snap.docs.map((d) => QueueGroup.fromDoc(d.id, d.data()))),
    );
  }

  Future<List<QueueGroup>> fetchGroups() async {
    try {
      final snap = await _groups.get();
      return sortGroups(
        snap.docs.map((d) => QueueGroup.fromDoc(d.id, d.data())),
      );
    } catch (e, s) {
      throwGroupError(e, s);
    }
  }

  Future<QueueGroup> createGroup(String name) async {
    try {
      final count = await _groups.count().get();
      if ((count.count ?? 0) >= QueueGroup.maxPerOwner) {
        throw const GroupLimitReachedException();
      }
      final now = DateTime.now();
      final ref = await _groups.add({
        'name': name.trim(),
        'createdAt': Timestamp.fromDate(now),
      });
      return QueueGroup(id: ref.id, name: name.trim(), createdAt: now);
    } on GroupLimitReachedException {
      rethrow;
    } catch (e, s) {
      throwGroupError(e, s);
    }
  }

  Future<void> renameGroup(String groupId, String name) async {
    try {
      await _groups.doc(groupId).update({'name': name.trim()});
    } catch (e, s) {
      throwGroupError(e, s);
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      final queues = await _firestore
          .collection('queues')
          .where('ownerId', isEqualTo: _uid)
          .where('groupId', isEqualTo: groupId)
          .get();
      for (final chunk in chunkList(queues.docs, groupBatchLimit)) {
        final batch = _firestore.batch();
        for (final q in chunk) {
          batch.update(q.reference, {'groupId': FieldValue.delete()});
        }
        await batch.commit();
      }
      await _groups.doc(groupId).delete();
    } catch (e, s) {
      throwGroupError(e, s);
    }
  }

  Future<void> setQueueGroup(String queueId, String? groupId) async {
    try {
      await _firestore.collection('queues').doc(queueId).update({
        'groupId': groupId ?? FieldValue.delete(),
      });
    } catch (e, s) {
      throwGroupError(e, s);
    }
  }
}
