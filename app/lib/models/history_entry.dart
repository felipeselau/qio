import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.ticket,
    required this.name,
    this.phone,
    required this.result,
    required this.joinedAt,
    this.calledAt,
    this.finishedAt,
    this.calledBy,
    this.operatorId,
  });

  final String id;
  final int ticket;
  final String name;
  final String? phone;
  final String result;
  final DateTime joinedAt;
  final DateTime? calledAt;
  final DateTime? finishedAt;
  final String? calledBy;
  final String? operatorId;

  String? get attendantId {
    if (calledBy != null && calledBy!.isNotEmpty) return calledBy;
    if (operatorId != null && operatorId!.isNotEmpty) return operatorId;
    return null;
  }

  bool get isServed => result == 'served';
  bool get isNoShow => result == 'no_show';
  bool get isLeft => result == 'left';

  DateTime get referenceTime => finishedAt ?? joinedAt;

  Duration? get wait => calledAt?.difference(joinedAt);

  Duration? get service => calledAt != null && finishedAt != null
      ? finishedAt!.difference(calledAt!)
      : null;

  static DateTime? _toDate(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  factory HistoryEntry.fromDoc(String id, Map<String, dynamic> data) {
    return HistoryEntry(
      id: id,
      ticket: (data['ticket'] as num?)?.toInt() ?? 0,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String?,
      result: data['result'] as String? ?? '',
      joinedAt:
          _toDate(data['joinedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      calledAt: _toDate(data['calledAt']),
      finishedAt: _toDate(data['finishedAt']),
      calledBy: data['calledBy'] as String?,
      operatorId: data['operatorId'] as String?,
    );
  }
}
