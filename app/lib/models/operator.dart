import 'package:cloud_firestore/cloud_firestore.dart';

enum OperatorRequestStatus { pending, approved, rejected }

extension OperatorRequestStatusX on OperatorRequestStatus {
  String get value {
    switch (this) {
      case OperatorRequestStatus.pending:
        return 'pending';
      case OperatorRequestStatus.approved:
        return 'approved';
      case OperatorRequestStatus.rejected:
        return 'rejected';
    }
  }

  static OperatorRequestStatus fromValue(String? v) {
    switch (v) {
      case 'approved':
        return OperatorRequestStatus.approved;
      case 'rejected':
        return OperatorRequestStatus.rejected;
      default:
        return OperatorRequestStatus.pending;
    }
  }
}

DateTime? _toDate(dynamic v) => v is Timestamp ? v.toDate() : null;

class QueueOperator {
  QueueOperator({
    required this.uid,
    required this.queueId,
    required this.queueName,
    this.displayName,
    this.email,
    this.addedAt,
    this.addedBy,
  });

  final String uid;
  final String queueId;
  final String queueName;
  final String? displayName;
  final String? email;
  final DateTime? addedAt;
  final String? addedBy;

  String get label => displayName ?? email ?? uid;

  factory QueueOperator.fromDoc(String uid, Map<String, dynamic> data) {
    return QueueOperator(
      uid: uid,
      queueId: data['queueId'] as String? ?? '',
      queueName: data['queueName'] as String? ?? '',
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      addedAt: _toDate(data['addedAt']),
      addedBy: data['addedBy'] as String?,
    );
  }
}

class OperatorRequest {
  OperatorRequest({
    required this.uid,
    required this.queueId,
    required this.queueName,
    required this.status,
    this.displayName,
    this.email,
    this.requestedAt,
    this.respondedAt,
  });

  final String uid;
  final String queueId;
  final String queueName;
  final OperatorRequestStatus status;
  final String? displayName;
  final String? email;
  final DateTime? requestedAt;
  final DateTime? respondedAt;

  String get label => displayName ?? email ?? uid;

  factory OperatorRequest.fromDoc(String uid, Map<String, dynamic> data) {
    return OperatorRequest(
      uid: uid,
      queueId: data['queueId'] as String? ?? '',
      queueName: data['queueName'] as String? ?? '',
      status: OperatorRequestStatusX.fromValue(data['status'] as String?),
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      requestedAt: _toDate(data['requestedAt']),
      respondedAt: _toDate(data['respondedAt']),
    );
  }
}
