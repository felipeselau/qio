import 'package:cloud_firestore/cloud_firestore.dart';

import 'queue.dart';

class QueueGroup {
  const QueueGroup({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  static const maxPerOwner = 20;
  static const maxNameLength = 40;

  final String id;
  final String name;
  final DateTime createdAt;

  factory QueueGroup.fromDoc(String id, Map<String, dynamic> data) {
    final raw = data['createdAt'];
    return QueueGroup(
      id: id,
      name: data['name'] as String? ?? '',
      createdAt: raw is Timestamp
          ? raw.toDate()
          : raw is DateTime
          ? raw
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

String? resolveGroupId(Queue queue, Iterable<QueueGroup> groups) {
  final id = queue.groupId;
  if (id == null || id.isEmpty) return null;
  return groups.any((g) => g.id == id) ? id : null;
}
