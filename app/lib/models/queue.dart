enum QueueStatus { open, paused, closed }

extension QueueStatusX on QueueStatus {
  String get label {
    switch (this) {
      case QueueStatus.open:
        return 'Aberta';
      case QueueStatus.paused:
        return 'Pausada';
      case QueueStatus.closed:
        return 'Fechada';
    }
  }

  String get value {
    switch (this) {
      case QueueStatus.open:
        return 'open';
      case QueueStatus.paused:
        return 'paused';
      case QueueStatus.closed:
        return 'closed';
    }
  }

  static QueueStatus fromValue(String? v) {
    switch (v) {
      case 'paused':
        return QueueStatus.paused;
      case 'closed':
        return QueueStatus.closed;
      default:
        return QueueStatus.open;
    }
  }
}

class Queue {
  Queue({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.status = QueueStatus.open,
    this.avgServiceMin = 10,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final QueueStatus status;
  final int avgServiceMin;
  final DateTime createdAt;

  factory Queue.fromDoc(String id, Map<String, dynamic> data) {
    return Queue(
      id: id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      status: QueueStatusX.fromValue(data['status'] as String?),
      avgServiceMin: (data['avgServiceMin'] as num?)?.toInt() ?? 10,
      createdAt: (data['createdAt'] as dynamic) is DateTime
          ? data['createdAt'] as DateTime
          : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'name': name,
    'description': description,
    'status': status.value,
    'avgServiceMin': avgServiceMin,
    'createdAt': createdAt.toIso8601String(),
  };
}
