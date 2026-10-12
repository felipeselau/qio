import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/painting.dart';

import '../services/brand_palette.dart';
import 'queue.dart';

class QueueGroup {
  const QueueGroup({
    required this.id,
    required this.name,
    required this.createdAt,
    this.colorHex,
    this.order,
  });

  static const maxPerOwner = 20;
  static const maxNameLength = 40;
  static const maxOrder = 1000;

  final String id;
  final String name;
  final DateTime createdAt;
  final String? colorHex;
  final int? order;

  Color? get color {
    final hex = colorHex;
    if (hex == null) return null;
    for (final c in brandPalette) {
      if (c.hex == hex.toUpperCase()) return c.color;
    }
    return null;
  }

  factory QueueGroup.fromDoc(String id, Map<String, dynamic> data) {
    final raw = data['createdAt'];
    final hex = data['colorHex'];
    final order = data['order'];
    return QueueGroup(
      id: id,
      name: data['name'] as String? ?? '',
      createdAt: raw is Timestamp
          ? raw.toDate()
          : raw is DateTime
          ? raw
          : DateTime.fromMillisecondsSinceEpoch(0),
      colorHex: hex is String && isValidBrandHex(hex)
          ? hex.toUpperCase()
          : null,
      order: order is num && order >= 0 && order <= maxOrder
          ? order.toInt()
          : null,
    );
  }
}

String? resolveGroupId(Queue queue, Iterable<QueueGroup> groups) {
  final id = queue.groupId;
  if (id == null || id.isEmpty) return null;
  return groups.any((g) => g.id == id) ? id : null;
}
