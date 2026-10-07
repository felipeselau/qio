import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../l10n/app_localizations.dart';
import '../models/operator.dart';

enum OperatorInviteError {
  generateFailed,
  invalid,
  invalidOrRevoked,
  expired,
  ownQueue,
}

class OperatorInviteException implements Exception {
  OperatorInviteException(this.error);

  final OperatorInviteError error;

  String message(AppLocalizations l10n) => switch (error) {
    OperatorInviteError.generateFailed => l10n.inviteGenerateFailed,
    OperatorInviteError.invalid => l10n.inviteInvalid,
    OperatorInviteError.invalidOrRevoked => l10n.inviteInvalidOrRevoked,
    OperatorInviteError.expired => l10n.inviteExpired,
    OperatorInviteError.ownQueue => l10n.inviteOwnQueue,
  };

  @override
  String toString() => error.name;
}

class OperatorService {
  OperatorService._();
  static final OperatorService instance = OperatorService._();

  static const Duration defaultInviteValidity = Duration(hours: 24);
  static const String _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int _codeLength = 6;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Random _random = Random.secure();

  String get _uid => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection('operatorInvites');

  DocumentReference<Map<String, dynamic>> _queueDoc(String queueId) =>
      _firestore.collection('queues').doc(queueId);

  static String normalizeCode(String code) =>
      code.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  String _newCode() => List.generate(
    _codeLength,
    (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
  ).join();

  Future<String> generateOperatorInvite(
    String queueId, {
    Duration? validFor = defaultInviteValidity,
  }) async {
    final queueSnap = await _queueDoc(queueId).get();
    final queueData = queueSnap.data() ?? {};
    final oldCode = queueData['operatorInviteCode'] as String?;

    String? code;
    for (var i = 0; i < 5 && code == null; i++) {
      final candidate = _newCode();
      final existing = await _invites.doc(candidate).get();
      if (!existing.exists) code = candidate;
    }
    if (code == null) {
      throw OperatorInviteException(OperatorInviteError.generateFailed);
    }

    final expiresAt = validFor == null
        ? null
        : Timestamp.fromDate(DateTime.now().add(validFor));
    final batch = _firestore.batch();
    if (oldCode != null) batch.delete(_invites.doc(oldCode));
    batch.set(_invites.doc(code), {
      'queueId': queueId,
      'ownerId': _uid,
      'queueName': queueData['name'] as String? ?? '',
      'expiresAt': expiresAt,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_queueDoc(queueId), {
      'operatorInviteCode': code,
      'operatorInviteExpiresAt': expiresAt,
    });
    await batch.commit();
    return code;
  }

  Future<void> revokeOperatorInvite(String queueId) async {
    final queueSnap = await _queueDoc(queueId).get();
    final code = queueSnap.data()?['operatorInviteCode'] as String?;
    final batch = _firestore.batch();
    if (code != null) batch.delete(_invites.doc(code));
    batch.update(_queueDoc(queueId), {
      'operatorInviteCode': FieldValue.delete(),
      'operatorInviteExpiresAt': FieldValue.delete(),
    });
    await batch.commit();
  }

  Future<OperatorRequest> requestToJoinAsOperator(String rawCode) async {
    final code = normalizeCode(rawCode);
    if (code.length != _codeLength) {
      throw OperatorInviteException(OperatorInviteError.invalid);
    }
    final inviteSnap = await _invites.doc(code).get();
    final invite = inviteSnap.data();
    if (invite == null) {
      throw OperatorInviteException(OperatorInviteError.invalidOrRevoked);
    }
    final expiresAt = invite['expiresAt'];
    if (expiresAt is Timestamp &&
        isInviteExpired(expiresAt.toDate(), DateTime.now())) {
      throw OperatorInviteException(OperatorInviteError.expired);
    }
    if (invite['ownerId'] == _uid) {
      throw OperatorInviteException(OperatorInviteError.ownQueue);
    }

    final queueId = invite['queueId'] as String;
    final queueName = invite['queueName'] as String? ?? '';
    final requestRef = _queueDoc(
      queueId,
    ).collection('operatorRequests').doc(_uid);

    final existing = await requestRef.get();
    final existingData = existing.data();
    if (existingData != null &&
        OperatorRequestStatusX.fromValue(existingData['status'] as String?) ==
            OperatorRequestStatus.pending) {
      return OperatorRequest.fromDoc(_uid, existingData);
    }

    final user = _auth.currentUser;
    await requestRef.set({
      'uid': _uid,
      'queueId': queueId,
      'queueName': queueName,
      'code': code,
      'status': OperatorRequestStatus.pending.value,
      'displayName': user?.displayName,
      'email': user?.email,
      'requestedAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
    });
    return OperatorRequest(
      uid: _uid,
      queueId: queueId,
      queueName: queueName,
      status: OperatorRequestStatus.pending,
      displayName: user?.displayName,
      email: user?.email,
    );
  }

  Stream<OperatorRequest?> watchMyRequest(String queueId) {
    return _queueDoc(
      queueId,
    ).collection('operatorRequests').doc(_uid).snapshots().map((d) {
      final data = d.data();
      return data == null ? null : OperatorRequest.fromDoc(d.id, data);
    });
  }

  Stream<List<OperatorRequest>> watchMyRequests() {
    return _firestore
        .collectionGroup('operatorRequests')
        .where('uid', isEqualTo: _uid)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => OperatorRequest.fromDoc(d.id, d.data()))
              .where((r) => r.status != OperatorRequestStatus.approved)
              .toList(),
        );
  }

  Future<void> cancelMyRequest(String queueId) async {
    await _queueDoc(queueId).collection('operatorRequests').doc(_uid).delete();
  }

  Stream<List<QueueOperator>> watchMyOperatorQueues() {
    return _firestore
        .collectionGroup('operators')
        .where('uid', isEqualTo: _uid)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => QueueOperator.fromDoc(d.id, d.data()))
              .toList(),
        );
  }

  Stream<bool> watchIsOperator(String queueId) {
    return _queueDoc(queueId)
        .collection('operators')
        .doc(_uid)
        .snapshots()
        .map((d) => d.exists)
        .transform(
          StreamTransformer<bool, bool>.fromHandlers(
            handleError: (_, _, sink) => sink.add(false),
          ),
        );
  }

  Stream<List<OperatorRequest>> watchOperatorRequests(String queueId) {
    return _queueDoc(queueId)
        .collection('operatorRequests')
        .where('status', isEqualTo: OperatorRequestStatus.pending.value)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => OperatorRequest.fromDoc(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<QueueOperator>> watchOperators(String queueId) {
    return _queueDoc(queueId)
        .collection('operators')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => QueueOperator.fromDoc(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> approveOperatorRequest(
    String queueId,
    OperatorRequest request,
  ) async {
    final queueRef = _queueDoc(queueId);
    final batch = _firestore.batch();
    batch.set(queueRef.collection('operators').doc(request.uid), {
      'uid': request.uid,
      'queueId': queueId,
      'queueName': request.queueName,
      'displayName': request.displayName,
      'email': request.email,
      'addedAt': FieldValue.serverTimestamp(),
      'addedBy': _uid,
    });
    batch.update(queueRef.collection('operatorRequests').doc(request.uid), {
      'status': OperatorRequestStatus.approved.value,
      'respondedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await syncOperatorMirror(queueId);
  }

  Future<void> rejectOperatorRequest(String queueId, String uid) async {
    await _queueDoc(queueId).collection('operatorRequests').doc(uid).update({
      'status': OperatorRequestStatus.rejected.value,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeOperator(String queueId, String uid) async {
    final queueRef = _queueDoc(queueId);
    final requestRef = queueRef.collection('operatorRequests').doc(uid);
    final request = await requestRef.get();
    final batch = _firestore.batch();
    batch.delete(queueRef.collection('operators').doc(uid));
    if (request.exists) {
      batch.update(requestRef, {
        'status': OperatorRequestStatus.removed.value,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    await syncOperatorMirror(queueId);
  }

  Future<List<QueueOperator>> fetchOperators(String queueId) async {
    final snap = await _queueDoc(queueId).collection('operators').get();
    return snap.docs.map((d) => QueueOperator.fromDoc(d.id, d.data())).toList();
  }

  Future<void> syncOperatorMirror(String queueId) async {
    final snap = await _queueDoc(queueId).collection('operators').get();
    await _rtdb.ref('owners/$queueId').update({'ownerUid': _uid});
    await _rtdb
        .ref('queues/$queueId/operatorUids')
        .set(
          snap.docs.isEmpty ? null : {for (final d in snap.docs) d.id: true},
        );
  }

  Future<void> deleteOperatorData(String queueId) async {
    final queueRef = _queueDoc(queueId);
    final queueSnap = await queueRef.get();
    final code = queueSnap.data()?['operatorInviteCode'] as String?;
    final operators = await queueRef.collection('operators').get();
    final requests = await queueRef.collection('operatorRequests').get();
    final batch = _firestore.batch();
    if (code != null) batch.delete(_invites.doc(code));
    for (final d in [...operators.docs, ...requests.docs]) {
      batch.delete(d.reference);
    }
    await batch.commit();
    await _rtdb.ref('queues/$queueId/operatorUids').remove();
  }
}
